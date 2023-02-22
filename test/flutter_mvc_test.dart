import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestModel {
  TestModel(this.title);
  final String title;
}

class TestController extends MvcController<TestModel> {
  @override
  MvcView view(TestModel model) => MvcViewBuilder<TestController, TestModel>((context) => Text(model.title, textDirection: TextDirection.ltr));
}

class TestPorxyController extends MvcProxyController {}

void main() {
  testWidgets(
    "test mvc",
    (tester) async {
      await tester.pumpWidget(Mvc(create: () => TestController(), model: TestModel("1")));
      final titleFinder = find.text("1");
      expect(titleFinder, findsOneWidget);
      await tester.pumpWidget(Mvc(create: () => TestController(), model: TestModel("2")));
      final titleUpdatedFinder = find.text("2");
      expect(titleUpdatedFinder, findsOneWidget);
    },
  );

  testWidgets(
    "test find controller",
    (tester) async {
      late TestController controller1;
      late TestController controller2;
      late TestPorxyController parent;
      await tester.pumpWidget(
        MvcProxy(
          proxyCreate: () {
            parent = TestPorxyController();
            return parent;
          },
          child: Column(
            children: [
              Mvc(
                create: () {
                  controller1 = TestController();
                  return controller1;
                },
                model: TestModel("1"),
              ),
              Mvc(
                create: () {
                  controller2 = TestController();
                  return controller2;
                },
                model: TestModel("2"),
              ),
            ],
          ),
        ),
      );
      expect(controller1.parent<TestPorxyController>() == parent, isTrue);
      expect(controller2.parent<TestPorxyController>() == parent, isTrue);
      expect(controller1.nextSibling<TestController>() == controller2, isTrue);
      expect(controller2.previousSibling<TestController>() == controller1, isTrue);
      expect(parent.child<TestController>() == controller1 || parent.child<TestController>() == controller2, isTrue);
    },
  );

  testWidgets(
    "test state",
    (tester) async {
      TestPorxyController controller = TestPorxyController();
      MvcStateValue<int> parentIntStateValue = controller.initState<int>(1);
      MvcStateValue<int> parentIntKeyStateValue = controller.initState<int>(2, key: "parent");
      TestPorxyController child1 = TestPorxyController();
      var child1StringStateValue = child1.initState<String>("child1");
      var child1GlobalStateValue = child1.initState<String>("child1_global", global: true, key: "child1_global");
      TestPorxyController child2 = TestPorxyController();
      var child2StringStateValue = child2.initState<String>("child2");
      var child2GlobalStateValue = child2.initState<String>("child2_global", global: true, key: "child2_global");
      await tester.pumpWidget(
        MvcProxy(
          proxyCreate: () => controller,
          child: MvcStateScope(
            (state) {
              return Column(
                children: [
                  MvcProxy(
                    proxyCreate: () => child1,
                    child: MvcStateScope(
                      (state) {
                        return Text("${state.get<int>()}-${state.get<int>(key: "parent")}-${state.get<String>()}-${state.get<String>(key: "child2_global")}", textDirection: TextDirection.ltr);
                      },
                    ),
                  ),
                  MvcProxy(
                    proxyCreate: () => child2,
                    child: MvcStateScope(
                      (state) {
                        return Text("${state.get<int>()}-${state.get<int>(key: "parent")}-${state.get<String>()}-${state.get<String>(key: "child1_global")}", textDirection: TextDirection.ltr);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      late Finder child1TextFinder;
      late Finder child2TextFinder;
      child1TextFinder = find.text("${parentIntStateValue.value}-${parentIntKeyStateValue.value}-${child1StringStateValue.value}-${child2GlobalStateValue.value}");
      expect(child1TextFinder, findsOneWidget);
      child2TextFinder = find.text("${parentIntStateValue.value}-${parentIntKeyStateValue.value}-${child2StringStateValue.value}-${child1GlobalStateValue.value}");
      expect(child2TextFinder, findsOneWidget);

      controller.updateState<int>(updater: (state) => state.value = 2);
      controller.updateState<int>(updater: (state) => state.value = 3, key: "parent");
      child1.updateState<String>(updater: (state) => state.value = "child-1");
      child1.updateState<String>(updater: (state) => state.value = "child-1_global", key: "child1_global");
      child2.updateState<String>(updater: (state) => state.value = "child-2");
      child2.updateState<String>(updater: (state) => state.value = "child-2_global", key: "child2_global");
      await tester.pump();

      child1TextFinder = find.text("${parentIntStateValue.value}-${parentIntKeyStateValue.value}-${child1StringStateValue.value}-${child2GlobalStateValue.value}");
      expect(child1TextFinder, findsOneWidget);
      child2TextFinder = find.text("${parentIntStateValue.value}-${parentIntKeyStateValue.value}-${child2StringStateValue.value}-${child1GlobalStateValue.value}");
      expect(child2TextFinder, findsOneWidget);
    },
  );

  testWidgets(
    "test global state",
    (tester) async {},
  );
}
