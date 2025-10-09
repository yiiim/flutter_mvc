import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  testWidgets('should work with service provider builder', (tester) async {
    bool serviceResolved = false;

    await tester.pumpWidget(
      MvcApp(
        serviceProviderBuilder: (collection) {
          collection?.add<TestService>(
            (_) {
              serviceResolved = true;
              return TestService();
            },
            initializeWhenServiceProviderBuilt: true,
          );
        },
        child: Builder(
          builder: (context) {
            return Text('Service: $serviceResolved', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    expect(serviceResolved, isTrue);
    expect(find.text('Service: true'), findsOneWidget);
  });

  testWidgets('should handle widget rebuilds correctly', (tester) async {
    int buildCount = 0;

    await tester.pumpWidget(
      MvcApp(
        child: Builder(
          builder: (context) {
            buildCount++;
            return const Text('Simple Widget', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    expect(buildCount, equals(1));
    expect(find.text('Simple Widget'), findsOneWidget);

    // Trigger rebuild
    await tester.pumpWidget(
      MvcApp(
        child: Builder(
          builder: (context) {
            buildCount++;
            return const Text('Simple Widget', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    expect(buildCount, equals(2));
  });
}
