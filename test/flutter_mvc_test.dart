import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestModel {
  TestModel(this.title);
  final String title;
}

class TestController extends MvcController<TestModel> {
  TestController({
    this.viewBuilder,
  });
  final Widget Function(MvcContext<TestController, TestModel> context)? viewBuilder;
  @override
  MvcView view() {
    return MvcViewBuilder<TestController, TestModel>(
      (context) {
        if (viewBuilder != null) return viewBuilder!(context);
        return Text(context.model.title, textDirection: TextDirection.ltr);
      },
    );
  }
}

class TestModellessController extends MvcController {
  TestModellessController({this.viewBuilder});
  final Widget Function(MvcContext<TestModellessController, void> context)? viewBuilder;
  @override
  MvcView<MvcController, dynamic> view() {
    return MvcModelessViewBuilder<TestModellessController>(
      (context) {
        if (viewBuilder != null) return viewBuilder!(context);
        return Text(model.title, textDirection: TextDirection.ltr);
      },
    );
  }

  @override
  void initPart(MvcControllerPartCollection collection) {
    super.initPart(collection);
    collection.addPart(() => TestModellessControllerPart());
  }
}

class TestModellessControllerPart extends MvcControllerPart<TestModellessController> {}

class TestPorxyController extends MvcProxyController {
  void Function()? didDispose;
  @override
  void dispose() {
    super.dispose();
    didDispose?.call();
  }
}

void main() {
  testWidgets(
    "test model update",
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
    "test state",
    (tester) async {
      var controller = TestModellessController(
        viewBuilder: (context) {
          return MvcStateScope(
            (state) {
              return Builder(
                builder: (context) {
                  return Text(state.get<String>() ?? "0", textDirection: TextDirection.ltr);
                },
              );
            },
          );
        },
      );
      controller.initState("1");
      await tester.pumpWidget(Mvc(create: () => controller));
      final titleFinder = find.text("1");
      expect(titleFinder, findsOneWidget);
      controller.updateState<String>(updater: (state) => state.value = "2");
      await tester.pumpWidget(Mvc(create: () => controller));
      final titleUpdatedFinder = find.text("2");
      expect(titleUpdatedFinder, findsOneWidget);
    },
  );

  testWidgets(
    "test key state",
    (tester) async {
      var controller = TestModellessController(
        viewBuilder: (context) {
          return MvcStateScope(
            (state) {
              return Builder(
                builder: (context) {
                  return Text(state.get<String>() ?? "0", textDirection: TextDirection.ltr);
                },
              );
            },
          );
        },
      );
      controller.initState("1", key: "mykey");
      await tester.pumpWidget(Mvc(create: () => controller));
      final titleFinder = find.text("1");
      expect(titleFinder, findsOneWidget);
      controller.updateState<String>(updater: (state) => state.value = "2", key: "mykey");
      await tester.pumpWidget(Mvc(create: () => controller));
      final titleUpdatedFinder = find.text("2");
      expect(titleUpdatedFinder, findsOneWidget);
    },
  );

  testWidgets(
    "test parent status",
    (tester) async {
      var controller = TestModellessController(
        viewBuilder: (context) {
          return MvcStateScope(
            (state) {
              return Text(state.get<String>() ?? "0", textDirection: TextDirection.ltr);
            },
          );
        },
      );

      var parentController = TestModellessController(
        viewBuilder: (context) {
          return Mvc(create: () => controller);
        },
      );
      parentController.initState("1");

      await tester.pumpWidget(Mvc(create: () => parentController));
      final titleFinder = find.text("1");
      expect(titleFinder, findsOneWidget);
      parentController.updateState<String>(updater: (state) => state.value = "2");
      await tester.pumpWidget(Mvc(create: () => parentController));
      final titleUpdatedFinder = find.text("2");
      expect(titleUpdatedFinder, findsOneWidget);
    },
  );

  testWidgets(
    "test part status",
    (tester) async {
      var controller = TestModellessController(
        viewBuilder: (context) {
          return MvcStateScope(
            (state) {
              return Text(state.get<String>() ?? "0", textDirection: TextDirection.ltr);
            },
          );
        },
      );
      await tester.pumpWidget(Mvc(create: () => controller));
      var controllerPart = controller.getPart<TestModellessControllerPart>()!;
      expect(controllerPart.controller == controller, isTrue);

      final partNoneStateFinder = find.text("0");
      expect(partNoneStateFinder, findsOneWidget);

      controllerPart.initState("1");
      controller.update();
      await tester.pumpWidget(Mvc(create: () => controller));

      final partInitStateFinder = find.text("1");
      expect(partInitStateFinder, findsOneWidget);
      controllerPart.updateState<String>(updater: (state) => state.value = "2");
      await tester.pumpWidget(Mvc(create: () => controller));
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
    "test dispose",
    (tester) async {
      bool isDispose = false;
      TestPorxyController controller = TestPorxyController();
      controller.didDispose = () {
        isDispose = true;
      };
      await tester.pumpWidget(MvcProxy(proxyCreate: () => controller, child: const Placeholder()));
      expect(isDispose, isFalse);
      await tester.pumpWidget(const Placeholder());
      expect(isDispose, isTrue);
    },
  );
}
