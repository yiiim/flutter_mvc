import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';
import 'package:flutter_test/flutter_test.dart';
import 'common.dart';

void main() {
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
              builder: (context) => Column(
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
              child: MvcBody(
                key: rootKey,
                id: 'root',
                classes: const ['root'],
                attributes: const {"data-attr": "root"},
                builder: (context) {
                  return Column(
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
                  );
                },
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

      expect(Mvc.querySelector('#root'), rootUpdater);
      expect(Mvc.querySelector('#root[data-attr=root]'), rootUpdater);
      expect(Mvc.querySelector('#root[data-attr]'), rootUpdater);
      expect(Mvc.querySelector('#root[data-bttr]'), isNull);
      expect(Mvc.querySelector('#root[data-attr=child1]'), isNull);
      expect(Mvc.querySelector<MvcBody>(), rootUpdater);
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
    'test mvc break selector',
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
              builder: (context) => Column(
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
                      builder: (context) => MvcBuilder(
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
}
