import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'common.dart';

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
              builder: (context) => MvcBuilder(
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
              builder: (context) => MvcBuilder(
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
    'test controller update',
    (WidgetTester tester) async {
      var controller = TestController();
      controller.controllerValue = "controllerValue";

      await tester.pumpWidget(
        MvcApp(
          child: Mvc(
            create: () => controller,
            model: TestModel(
              "modelValue",
              builder: (context) => Text(
                controller.controllerValue,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );

      expect(find.text('controllerValue'), findsOneWidget);
      controller.controllerValue = "controllerValue2";
      controller.update();
      await tester.pump();
      expect(find.text('controllerValue2'), findsOneWidget);
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
                builder: (context) => MvcBuilder(
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
            model: TestModel("modelValue", builder: (context) => const SizedBox.shrink()),
          ),
        ),
      );

      expect(controller.isDisposed, false);

      await tester.pumpWidget(const SizedBox());

      expect(controller.isDisposed, true);
    },
  );
}
