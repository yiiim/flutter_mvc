// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';
import 'package:flutter_test/flutter_test.dart';

class TestMvcWidget extends MvcStatelessWidget {
  const TestMvcWidget({required this.builder, super.key, super.id, super.classes, super.attributes});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

class TestService with DependencyInjectionService, MvcDependentObject {
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
              child: MvcBuilder(
                builder: (context) {
                  return Text(context.getMvcService<TestController>().model.modelValue, textDirection: TextDirection.ltr);
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
              child: MvcBuilder(
                builder: (context) {
                  return Text(context.getMvcService<TestController>().model.modelValue, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), null);
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
                  MvcBuilder(
                    id: "id",
                    builder: (context) {
                      return Text("id_${context.getMvcService<TestController>().controllerValue}", textDirection: TextDirection.ltr);
                    },
                  ),
                  MvcBuilder(
                    classes: const ["cls"],
                    builder: (context) {
                      return Text("cls_${context.getMvcService<TestController>().controllerValue}", textDirection: TextDirection.ltr);
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
      controller.querySelectorAll(".cls").update();
      await tester.pump();

      expect(find.text('id_controllerValue'), findsOneWidget);
      expect(find.text('cls_controllerValue2'), findsOneWidget);

      controller.controllerValue = "controllerValue3";
      controller.querySelectorAll("#id").update();
      await tester.pump();

      expect(find.text('id_controllerValue3'), findsOneWidget);
      expect(find.text('cls_controllerValue2'), findsOneWidget);
    },
  );

  testWidgets(
    'Test compound selectors',
    (WidgetTester tester) async {
      GlobalKey rootKey = GlobalKey();
      GlobalKey child1Key = GlobalKey();
      GlobalKey child2Key = GlobalKey();
      GlobalKey child1DescendantsKey = GlobalKey();
      GlobalKey child2DescendantsKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MvcApp(
              key: rootKey,
              child: Column(
                children: [
                  MvcBuilder(
                    id: 'child1',
                    classes: const ['child1'],
                    attributes: const {"data-attr": "child1"},
                    key: child1Key,
                    builder: (_) {
                      return Column(
                        children: [
                          MvcBuilder(
                            id: 'child1Descendants',
                            classes: const ['child1Descendants'],
                            attributes: const {"data-attr": "child1Descendants"},
                            key: child1DescendantsKey,
                            builder: (_) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  MvcBuilder(
                    id: 'child2',
                    classes: const ['child2'],
                    attributes: const {"data-attr": "child2"},
                    key: child2Key,
                    builder: (_) {
                      return Column(
                        children: [
                          TestMvcWidget(
                            id: 'child2Descendants',
                            classes: const ['child2Descendants'],
                            attributes: const {"data-attr": "child2Descendants"},
                            key: child2DescendantsKey,
                            builder: (_) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      MvcWidgetUpdater rootUpdater = (rootKey.currentContext as MvcNodeMixin).debugUpdater;
      MvcWidgetUpdater child1Updater = (child1Key.currentContext as MvcNodeMixin).debugUpdater;
      MvcWidgetUpdater child2Updater = (child2Key.currentContext as MvcNodeMixin).debugUpdater;
      MvcWidgetUpdater child1DescendantsUpdater = (child1DescendantsKey.currentContext as MvcNodeMixin).debugUpdater;
      MvcWidgetUpdater child2DescendantsUpdater = (child2DescendantsKey.currentContext as MvcNodeMixin).debugUpdater;

      void expectWithOutSort(Iterable actual, Iterable expected) {
        expect(actual.sorted((a, b) => a.hashCode.compareTo(b.hashCode)), expected.sorted((a, b) => a.hashCode.compareTo(b.hashCode)));
      }

      expectWithOutSort(Mvc.querySelectorAll('*'), [rootUpdater, child1Updater, child2Updater, child1DescendantsUpdater, child2DescendantsUpdater]);
      expect(Mvc.querySelector('#root'), rootUpdater);
      expect(Mvc.querySelector('#root[data-attr=root]'), rootUpdater);
      expect(Mvc.querySelector('#root[data-attr]'), rootUpdater);
      expect(Mvc.querySelector('#root[data-bttr]'), isNull);
      expect(Mvc.querySelector('#root[data-attr=child1]'), isNull);
      expect(Mvc.querySelector<MvcApp>(), rootUpdater);
      expectWithOutSort(Mvc.querySelector('#root')?.querySelectorAll('*') ?? <MvcWidgetUpdater>[], [child1Updater, child2Updater, child1DescendantsUpdater, child2DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelectorAll('#root TestMvcWidget'), [child2DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelector('#root')?.querySelectorAll('TestMvcWidget') ?? <MvcWidgetUpdater>[], [child2DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelectorAll('#root MvcBuilder'), [child1Updater, child2Updater, child1DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelectorAll('#root .child1'), [child1Updater]);
      expectWithOutSort(Mvc.querySelectorAll('#root .child2Descendants'), [child2DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelectorAll('#root TestMvcWidget[data-attr=child2Descendants]'), [child2DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelectorAll('#root TestMvcWidget[data-attr]'), [child2DescendantsUpdater]);
      expectWithOutSort(Mvc.querySelectorAll('#root TestMvcWidget[data-attr=child1Descendants]'), []);
      expectWithOutSort(Mvc.querySelectorAll('#root TestMvcWidget[data-bttr]'), []);
      expect(Mvc.querySelectorAll('#child1'), [child1Updater]);
      expect(Mvc.querySelectorAll('.child1'), [child1Updater]);
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
      controller.querySelectorAll<TestMvcWidget>().update();
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
      controller.getService<TestService>().update(() => service.stateValue = "serviceValue2");
      await tester.pump();
      expect(find.text('serviceValue2'), findsOneWidget);

      service.stateValue = "serviceValue3";
      service.update();
      await tester.pump();
      expect(find.text('serviceValue3'), findsOneWidget);
    },
  );

  testWidgets(
    'test mvc service',
    (tester) async {
      var service = TestService();
      service.stateValue = '1';
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) => collection.addSingleton<TestService>((_) => service),
            child: MvcServiceScope<TestService>(
              builder: (context, service) {
                return Text(service.stateValue, textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      service.update(() => service.stateValue = '2');
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'test depend on service',
    (tester) async {
      var service = TestService();
      service.stateValue = '1';
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) => collection.addSingleton<TestService>((_) => service),
            child: MvcBuilder(
              builder: (context) {
                return Text(context.dependOnMvcServiceOfExactType<TestService>().stateValue, textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      service.update(() => service.stateValue = '2');
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
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
      controller.querySelectorAll('.cls').update();
      await tester.pump();

      expect(find.text('controllerValue'), findsNothing);
      expect(find.text('controllerValue2'), findsOneWidget);
      expect(find.text('childControllerValue'), findsOneWidget);
      expect(find.text('childControllerValue2'), findsNothing);

      controller.controllerValue = "controllerValue3";
      childController.controllerValue = "childControllerValue3";
      childController.querySelectorAll(".cls").update();
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
                child: MvcBuilder(
                  builder: (context) {
                    return Text(context.getMvcService<TestController>().controllerValue, textDirection: TextDirection.ltr);
                  },
                ),
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

      expect(controller.isDisposed, false);

      await tester.pumpWidget(const SizedBox());

      expect(controller.isDisposed, true);
    },
  );

  testWidgets(
    "test mvcapp",
    (tester) async {
      ServiceCollection collection = ServiceCollection();
      collection.add<TestService>((_) => TestService());
      collection.addController((_) => TestController());
      var provider = collection.build();
      await tester.pumpWidget(
        MvcApp(
          serviceProvider: provider,
          child: const Mvc<TestController, TestModel>(
            model: TestModel("modelValue", child: SizedBox.shrink()),
          ),
        ),
      );
      expect(tester.takeException(), null);
    },
  );
}
