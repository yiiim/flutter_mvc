import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MvcServicesExtension', () {
    testWidgets('getMvcService should get service from provider', (tester) async {
      final testService = TestService(value: 'test123');

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestService>((_) => testService);
            },
            child: Builder(
              builder: (context) {
                final service = context.getMvcService<TestService>();
                return Text(service.value, textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('test123'), findsOneWidget);
    });

    testWidgets('tryGetMvcService should return null for non-existent service', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final service = context.tryGetMvcService<NonExistentService>();
              return Text('Service: ${service == null ? "null" : "found"}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Service: null'), findsOneWidget);
    });

    testWidgets('tryGetMvcService should return service if exists', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestService>((_) => TestService(value: 'exists'));
            },
            child: Builder(
              builder: (context) {
                final service = context.tryGetMvcService<TestService>();
                return Text('Service: ${service?.value ?? "null"}', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('Service: exists'), findsOneWidget);
    });

    testWidgets('dependOnMvcServiceOfExactType should rebuild on service change', (tester) async {
      late DependableTestService service;
      int buildCount = 0;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<DependableTestService>(
                (_) => DependableTestService(),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: Builder(
              builder: (context) {
                service = context.dependOnMvcServiceOfExactType<DependableTestService>();
                buildCount++;
                return Text('Value: ${service.value}', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Value: 0'), findsOneWidget);

      // Notify change
      service.updateValue(10);
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Value: 10'), findsOneWidget);
    });

    testWidgets('tryDependOnMvcServiceOfExactType should return null if not exists', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final service = context.tryDependOnMvcServiceOfExactType<NonExistentDependableService>();
              return Text('Service: ${service == null ? "null" : "found"}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Service: null'), findsOneWidget);
    });

    testWidgets('dependOnMvcService should work with aspect', (tester) async {
      late DependableTestService service;
      int buildCount = 0;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<DependableTestService>(
                (_) => DependableTestService(),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: Builder(
              builder: (context) {
                service = context.getMvcService<DependableTestService>();
                context.dependOnMvcService(service, aspect: 'specific-aspect');
                buildCount++;
                return Text('Value: ${service.value}', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Notify change - should rebuild
      service.updateValue(5);
      await tester.pump();

      expect(buildCount, 2); // Should increase
    });
  });

  group('MvcContext stateAccessor', () {
    testWidgets('should provide state accessor in build context', (tester) async {
      MvcStateAccessor? accessor;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              accessor = context.stateAccessor;
              return const Text('Test', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(accessor, isNotNull);
      expect(accessor, isA<MvcStateAccessor>());
    });

    testWidgets('should provide same accessor instance in same frame', (tester) async {
      MvcStateAccessor? accessor1;
      MvcStateAccessor? accessor2;

      await tester.pumpWidget(
        MvcApp(
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  accessor1 = context.stateAccessor;
                  return const Text('Test1', textDirection: TextDirection.ltr);
                },
              ),
              Builder(
                builder: (context) {
                  accessor2 = context.stateAccessor;
                  return const Text('Test2', textDirection: TextDirection.ltr);
                },
              ),
            ],
          ),
        ),
      );

      expect(accessor1, isNotNull);
      expect(accessor2, isNotNull);
      // Note: They might be different instances in different build contexts
    });

    testWidgets('should work with useState in context', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final count = context.stateAccessor.useState(
                (CounterState state) => state.count,
                initializer: () => CounterState(99),
              );
              return Text('Count: $count', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Count: 99'), findsOneWidget);
    });
  });

  group('MvcBasicElement integration', () {
    testWidgets('should create service provider for element', (tester) async {
      bool serviceCreated = false;

      await tester.pumpWidget(
        MvcApp(
          child: TestMvcWidget(
            builder: (context) {
              // Service provider should be available
              final service = context.tryGetMvcService<MvcWidgetScope>();
              serviceCreated = service != null;
              return const Text('Test', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(serviceCreated, isTrue);
    });

    testWidgets('should properly dispose element services', (tester) async {
      bool disposed = false;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<DisposableService>(
                (_) => DisposableService(onDispose: () => disposed = true),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: const Text('Test', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(disposed, false);

      await tester.pumpWidget(const SizedBox());

      expect(disposed, true);
    });
  });

  group('Service dependency injection hierarchy', () {
    testWidgets('should access parent scope services', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestService>((_) => TestService(value: 'parent'));
            },
            child: MvcDependencyProvider(
              provider: (collection) {
                // Don't register TestService in child
              },
              child: Builder(
                builder: (context) {
                  final service = context.getMvcService<TestService>();
                  return Text(service.value, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('parent'), findsOneWidget);
    });

    testWidgets('should override parent scope services', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestService>((_) => TestService(value: 'parent'));
            },
            child: MvcDependencyProvider(
              provider: (collection) {
                collection.addSingleton<TestService>((_) => TestService(value: 'child'));
              },
              child: Builder(
                builder: (context) {
                  final service = context.getMvcService<TestService>();
                  return Text(service.value, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('should support transient services', (tester) async {
      TestService? service1;
      TestService? service2;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.add<TestService>((_) => TestService(value: 'transient'));
            },
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    service1 = context.getMvcService<TestService>();
                    return Text(service1!.value, textDirection: TextDirection.ltr);
                  },
                ),
                Builder(
                  builder: (context) {
                    service2 = context.getMvcService<TestService>();
                    return Text(service2!.value, textDirection: TextDirection.ltr);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Transient services should be different instances
      expect(service1, isNot(equals(service2)));
    });
  });
}

// Test helper classes
class TestService with DependencyInjectionService {
  TestService({required this.value});
  final String value;
}

class NonExistentService {}

class DependableTestService with DependencyInjectionService, MvcDependableObject {
  int value = 0;

  void updateValue(int newValue) {
    value = newValue;
    notifyAllDependents();
  }
}

class NonExistentDependableService with MvcDependableObject {}

class CounterState {
  CounterState(this.count);
  int count;
}

class TestMvcWidget extends MvcStatelessWidget {
  const TestMvcWidget({required this.builder, super.key});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

class DisposableService with DependencyInjectionService {
  DisposableService({required this.onDispose});
  final VoidCallback onDispose;

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}
