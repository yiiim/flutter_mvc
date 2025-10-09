import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../common.dart';

void main() {
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
}
