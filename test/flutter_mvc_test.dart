// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestMvcWidget<TControllerType extends MvcController> extends MvcStatelessWidget<TControllerType> {
  const TestMvcWidget({required this.builder, super.key});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

class TestService with DependencyInjectionService, MvcService {
  TestService();
  String stateValue = "";
}

class TestModel {
  const TestModel(this.modelValue, {required this.child});
  final String modelValue;
  final Widget child;
}

class TestView extends MvcView<TestController> {
  @override
  Widget buildView() {
    return controller.model.child;
    // return Column(
    //   children: [
    //     Text(controller.model.modelValue, textDirection: TextDirection.ltr),
    //     MvcBuilder(
    //       id: "id",
    //       classes: const ["cls"],
    //       builder: (context) {
    //         return Text(controller.controllerValue, textDirection: TextDirection.ltr);
    //       },
    //     ),
    //     if (controller.model.child != null) !,
    //   ],
    // );
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
          child: Mvc<TestController, TestModel>(
            create: () => controller,
            model: TestModel(
              "modelValue",
              child: MvcBuilder<TestController>(
                builder: (context) {
                  return Text(context.controller.model.modelValue, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('modelValue'), findsOneWidget);

      await tester.pumpWidget(
        MvcApp(
          child: Mvc<TestController, TestModel>(
            create: () {
              throw Exception("should't create controller");
            },
            model: TestModel(
              "modelValue2",
              child: MvcBuilder<TestController>(
                builder: (context) {
                  return Text(context.controller.model.modelValue, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
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
            model: TestModel(
              "modelValue",
              child: Column(
                children: [
                  MvcBuilder<TestController>(
                    id: "id",
                    builder: (context) {
                      return Text("id_${context.controller.controllerValue}", textDirection: TextDirection.ltr);
                    },
                  ),
                  MvcBuilder<TestController>(
                    classes: const ["cls"],
                    builder: (context) {
                      return Text("cls_${context.controller.controllerValue}", textDirection: TextDirection.ltr);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('id_controllerValue'), findsOneWidget);
      expect(find.text('cls_controllerValue'), findsOneWidget);

      controller.controllerValue = "controllerValue2";
      controller.$(".cls").update();
      await tester.pump();

      expect(find.text('id_controllerValue'), findsOneWidget);
      expect(find.text('cls_controllerValue2'), findsOneWidget);

      controller.controllerValue = "controllerValue3";
      controller.$("#id").update();
      await tester.pump();

      expect(find.text('id_controllerValue3'), findsOneWidget);
      expect(find.text('cls_controllerValue2'), findsOneWidget);
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
            model: TestModel(
              "modelValue",
              child: TestMvcWidget(
                builder: (context) {
                  return Text(controller.controllerValue, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsOneWidget);

      controller.controllerValue = "controllerValue2";
      controller.$<TestMvcWidget>().update();
      await tester.pump();

      expect(find.text('controllerValue2'), findsOneWidget);
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
            provider: (collection) => collection.addSingleton<TestService>((_) => service),
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
      controller.updateService<TestService>(updater: (service) => service.stateValue = "serviceValue2");
      await tester.pump();
      expect(find.text('serviceValue2'), findsOneWidget);

      service.stateValue = "serviceValue3";
      service.update();
      await tester.pump();
      expect(find.text('serviceValue3'), findsOneWidget);
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
              child: Column(
                children: [
                  MvcBuilder(
                    classes: const ['cls'],
                    builder: (context) {
                      return Text(controller.controllerValue, textDirection: TextDirection.ltr);
                    },
                  ),
                  Mvc<TestController, TestModel>(
                    create: () => childController,
                    model: TestModel(
                      "childModelValue",
                      child: MvcBuilder(
                        classes: const ['cls'],
                        builder: (context) {
                          return Text(childController.controllerValue, textDirection: TextDirection.ltr);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsOneWidget);
      expect(find.text('childControllerValue'), findsOneWidget);

      controller.controllerValue = "controllerValue2";
      childController.controllerValue = "childControllerValue2";
      controller.$('.cls').update();
      await tester.pump();

      expect(find.text('controllerValue'), findsNothing);
      expect(find.text('controllerValue2'), findsOneWidget);
      expect(find.text('childControllerValue'), findsOneWidget);
      expect(find.text('childControllerValue2'), findsNothing);

      controller.controllerValue = "controllerValue3";
      childController.controllerValue = "childControllerValue3";
      childController.$(".cls").update();
      await tester.pump();

      expect(find.text('controllerValue'), findsNothing);
      expect(find.text('controllerValue2'), findsOneWidget);
      expect(find.text('controllerValue3'), findsNothing);
      expect(find.text('childControllerValue'), findsNothing);
      expect(find.text('childControllerValue2'), findsNothing);
      expect(find.text('childControllerValue3'), findsOneWidget);
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
            child: Mvc<TestController, TestModel>(
              model: TestModel(
                "modelValue",
                child: MvcBuilder<TestController>(builder: (context) {
                  return Text(context.controller.controllerValue, textDirection: TextDirection.ltr);
                }),
              ),
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsOneWidget);
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
            model: const TestModel("modelValue", child: SizedBox.shrink()),
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
            model: TestModel("modelValue", child: SizedBox.shrink()),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
