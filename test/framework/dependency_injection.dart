import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common.dart';

void main() {
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
                builder: (context) => Builder(
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
}
