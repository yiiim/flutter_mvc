// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestMvcWidget extends MvcStatelessWidget<TestController> {
  const TestMvcWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text((context as MvcContext<TestController>).controller.controllerValue, textDirection: TextDirection.ltr);
  }
}

class TestService with DependencyInjectionService, MvcService {
  TestService();
  String stateValue = "";
}

class TestModel {
  const TestModel(this.modelValue, {this.child});
  final String modelValue;
  final Widget? child;
}

class TestView extends MvcView<TestController> {
  @override
  Widget buildView() {
    return Column(
      children: [
        Text(controller.model.modelValue, textDirection: TextDirection.ltr),
        MvcBuilder(
          id: "id",
          classes: const ["cls"],
          builder: (context) {
            return Text(controller.controllerValue, textDirection: TextDirection.ltr);
          },
        ),
        if (controller.model.child != null) controller.model.child!,
      ],
    );
  }
}

class TestController extends MvcController<TestModel> {
  String controllerValue = "";
  bool isDisposed = false;
  @override
  MvcView view() => TestView();

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}

void main() {
  testWidgets(
    'test model update',
    (WidgetTester tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";
      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: const TestModel("modelValue"),
          ),
        ),
      );

      expect(find.text('modelValue'), findsOneWidget);
      expect(find.text('controllerValue'), findsOneWidget);

      controller.$(".cls").update();
      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: const TestModel("modelValue2"),
          ),
        ),
      );

      expect(find.text('modelValue2'), findsOneWidget);
    },
  );

  testWidgets(
    'test id and classes update',
    (WidgetTester tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";

      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: const TestModel(
              "modelValue",
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsOneWidget);

      controller.controllerValue = "controllerValue2";
      controller.$(".cls").update();
      await tester.pump();

      expect(find.text('controllerValue2'), findsOneWidget);

      controller.controllerValue = "controllerValue3";
      controller.$("#id").update();
      await tester.pump();

      expect(find.text('controllerValue3'), findsOneWidget);

      controller.controllerValue = "controllerValue4";
      controller.update();
      await tester.pump();

      expect(find.text('controllerValue4'), findsOneWidget);
    },
  );

  testWidgets(
    'test update widget',
    (WidgetTester tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";

      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: const TestModel(
              "modelValue",
              child: TestMvcWidget(),
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsNWidgets(2));

      controller.controllerValue = "controllerValue2";
      controller.updateWidget<TestMvcWidget>();
      await tester.pump();

      expect(find.text('controllerValue2'), findsNWidgets(1));
    },
  );
  testWidgets(
    'test update service',
    (WidgetTester tester) async {
      var controller = TestController();
      var service = TestService();
      service.stateValue = "serviceValue";

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) => collection.add<TestService>((_) => service),
            child: Mvc(
              create: () => controller,
              model: TestModel(
                "modelValue",
                child: MvcServiceScope<TestService>(
                  builder: (context, service) {
                    return Text(service.stateValue, textDirection: TextDirection.ltr);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('serviceValue'), findsOneWidget);
      service.stateValue = "serviceValue2";

      controller.updateService<TestService>();
      await tester.pump();

      expect(find.text('serviceValue2'), findsOneWidget);
    },
  );
  testWidgets(
    'test child mvc',
    (WidgetTester tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";

      var childController = TestController();
      childController.controllerValue = "childControllerValue";
      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: TestModel(
              "modelValue",
              child: Mvc<TestController, TestModel>(
                create: () => childController,
                model: const TestModel("childModelValue"),
              ),
            ),
          ),
        ),
      );

      expect(find.text('modelValue'), findsOneWidget);
      expect(find.text('childModelValue'), findsOneWidget);
      expect(find.text('controllerValue'), findsOneWidget);
      expect(find.text('childControllerValue'), findsOneWidget);

      controller.controllerValue = "controllerValue2";
      childController.controllerValue = "childControllerValue2";
      controller.$(".cls").update();
      await tester.pump();

      expect(find.text('controllerValue2'), findsOneWidget);
      expect(find.text('childControllerValue'), findsOneWidget);
      expect(find.text('childControllerValue2'), findsNothing);

      childController.$(".cls").update();
      await tester.pump();
      expect(find.text('childControllerValue2'), findsOneWidget);
    },
  );
  testWidgets(
    "test dependency provider",
    (tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) => collection.add<TestService>((_) => TestService()..stateValue = "objectValue"),
            child: Mvc(
              create: () => controller,
              model: TestModel(
                "modelValue",
                child: Builder(
                  builder: (context) {
                    return Text(controller.getService<TestService>().stateValue, textDirection: TextDirection.ltr);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('objectValue'), findsOneWidget);
    },
  );
  testWidgets(
    "test controller provider",
    (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addController((provider) => TestController()..controllerValue = "controllerValue");
            },
            child: const Mvc<TestController, TestModel>(
              model: TestModel("modelValue"),
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsOneWidget);
    },
  );

  testWidgets(
    "test service update",
    (tester) async {
      var serviceState = TestService();
      serviceState.stateValue = "serviceStateValue";
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.add((provider) => serviceState);
            },
            child: MvcServiceScope<TestService>(
              builder: (context, state) {
                return Text(state.stateValue, textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('serviceStateValue'), findsOneWidget);

      serviceState.stateValue = "serviceStateValue2";
      serviceState.update();
      await tester.pump();

      expect(find.text('serviceStateValue2'), findsOneWidget);
    },
  );

  testWidgets(
    "test controller dispose",
    (tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";
      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: const TestModel("modelValue"),
          ),
        ),
      );

      expect(controller.isDisposed, isFalse);

      await tester.pumpWidget(const SizedBox());

      expect(controller.isDisposed, isTrue);
    },
  );

  testWidgets(
    "test mvcowner",
    (tester) async {
      ServiceCollection collection = ServiceCollection();
      collection.add<TestService>((_) => TestService());
      collection.addController((_) => TestController());
      var provider = collection.build();
      await tester.pumpWidget(
        MvcApp(
          owner: MvcOwner(serviceProvider: provider),
          child: const Mvc<TestController, TestModel>(
            model: TestModel("modelValue"),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
