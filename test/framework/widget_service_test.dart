import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MvcWidgetService', () {
    testWidgets('should access context from service', (tester) async {
      MvcContext? capturedContext;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestWidgetService>(
                (_) => TestWidgetService(),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: Builder(
              builder: (context) {
                final service = context.getMvcService<TestWidgetService>();
                capturedContext = service.context;
                return const Text('Test', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(capturedContext, isNotNull);
      expect(capturedContext!.scope, isA<MvcWidgetScope>());
    });

    testWidgets('should trigger widget rebuild with update', (tester) async {
      late TestWidgetService service;
      int buildCount = 0;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addScopedSingleton<TestWidgetService>((_) => TestWidgetService());
            },
            child: MvcBuilder(
              builder: (context) {
                service = context.getMvcService<TestWidgetService>();
                buildCount++;
                return Text('Build: $buildCount', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Build: 1'), findsOneWidget);

      // Trigger update
      service.update(() {
        // Some state change
      });
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Build: 2'), findsOneWidget);
    });

    testWidgets('should call mvcWidgetActivate on activate', (tester) async {
      int activateCount = 0;
      GlobalKey widgetKey = GlobalKey();

      // First build with the widget
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            key: widgetKey,
            provider: (collection) {
              collection.addSingleton<TestWidgetServiceWithLifecycle>(
                (_) => TestWidgetServiceWithLifecycle(
                  onActivate: () => activateCount++,
                ),
              );
            },
            child: Builder(
              builder: (context) {
                context.getMvcService<TestWidgetServiceWithLifecycle>();
                return const Text('Test', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );
      expect(activateCount, equals(0));
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              return MvcDependencyProvider(
                key: widgetKey,
                provider: (collection) {
                  collection.addSingleton<TestWidgetServiceWithLifecycle>(
                    (_) => TestWidgetServiceWithLifecycle(
                      onActivate: () => activateCount++,
                    ),
                  );
                },
                child: Builder(
                  builder: (context) {
                    context.getMvcService<TestWidgetServiceWithLifecycle>();
                    return const Text('Test', textDirection: TextDirection.ltr);
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(activateCount, equals(1));
    });

    testWidgets('should call mvcWidgetDeactivate on deactivate', (tester) async {
      int deactivateCount = 0;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestWidgetServiceWithLifecycle>(
                (_) => TestWidgetServiceWithLifecycle(
                  onDeactivate: () => deactivateCount++,
                ),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: Builder(
              builder: (context) {
                context.getMvcService<TestWidgetServiceWithLifecycle>();
                return const Text('Test', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(deactivateCount, 0);

      // Remove the widget to trigger deactivate
      await tester.pumpWidget(const SizedBox());

      expect(deactivateCount, greaterThan(0));
    });

    testWidgets('should dispose properly', (tester) async {
      bool disposed = false;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestWidgetServiceWithDispose>(
                (_) => TestWidgetServiceWithDispose(
                  onDispose: () => disposed = true,
                ),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: Builder(
              builder: (context) {
                context.getMvcService<TestWidgetServiceWithDispose>();
                return const Text('Test', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(disposed, false);

      // Remove the widget to trigger dispose
      await tester.pumpWidget(const SizedBox());

      expect(disposed, true);
    });

    testWidgets('should work with scoped services', (tester) async {
      late TestWidgetService parentService;
      late TestWidgetService childService;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addScopedSingleton<TestWidgetService>(
                (_) => TestWidgetService(),
                initializeWhenServiceProviderBuilt: true,
              );
            },
            child: Builder(
              builder: (context) {
                parentService = context.getMvcService<TestWidgetService>();

                return MvcDependencyProvider(
                  provider: (collection) {
                    collection.addScopedSingleton<TestWidgetService>(
                      (_) => TestWidgetService(),
                      initializeWhenServiceProviderBuilt: true,
                    );
                  },
                  child: Builder(
                    builder: (context) {
                      childService = context.getMvcService<TestWidgetService>();
                      return const Text('Test', textDirection: TextDirection.ltr);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Should be different instances in different scopes
      expect(parentService, isNot(equals(childService)));
    });

    testWidgets('should maintain service across rebuilds', (tester) async {
      late TestWidgetService firstService;
      late TestWidgetService secondService;
      bool firstBuild = true;

      await tester.pumpWidget(
        MvcApp(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                return MvcDependencyProvider(
                  provider: (collection) {
                    collection.addSingleton<TestWidgetService>(
                      (_) => TestWidgetService(),
                      initializeWhenServiceProviderBuilt: true,
                    );
                  },
                  child: Builder(
                    builder: (context) {
                      if (firstBuild) {
                        firstService = context.getMvcService<TestWidgetService>();
                        firstBuild = false;
                      } else {
                        secondService = context.getMvcService<TestWidgetService>();
                      }
                      return ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Rebuild'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Trigger rebuild
      await tester.tap(find.text('Rebuild'));
      await tester.pump();

      // Should be the same instance
      expect(firstService, equals(secondService));
    });

    testWidgets('should update multiple times', (tester) async {
      late TestWidgetService service;
      int buildCount = 0;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addScopedSingleton<TestWidgetService>((_) => TestWidgetService());
            },
            child: MvcBuilder(
              builder: (context) {
                service = context.getMvcService<TestWidgetService>();
                buildCount++;
                return Text('Count: $buildCount', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      for (int i = 0; i < 5; i++) {
        service.update(() {});
        await tester.pump();
      }

      expect(buildCount, 6);
    });
  });

  group('MvcWidgetService with state', () {
    testWidgets('should access widget scope from service', (tester) async {
      late TestWidgetServiceWithState service;
      bool stateInitialized = false;

      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestWidgetServiceWithState>(
                (_) => TestWidgetServiceWithState(),
              );
            },
            child: Builder(
              builder: (context) {
                service = context.getMvcService<TestWidgetServiceWithState>();

                // Only initialize state once
                if (!stateInitialized) {
                  service.initializeState();
                  stateInitialized = true;
                }

                final count = context.stateAccessor.useState(
                  (ServiceCounterState state) => state.count,
                );
                return Text('Count: $count', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      service.increment();
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });
  });
}

// Test helper classes
class TestWidgetService with DependencyInjectionService, MvcWidgetService {}

class TestWidgetServiceWithLifecycle with DependencyInjectionService, MvcWidgetService {
  TestWidgetServiceWithLifecycle({this.onActivate, this.onDeactivate});

  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;

  @override
  void mvcWidgetActivate() {
    super.mvcWidgetActivate();
    onActivate?.call();
  }

  @override
  void mvcWidgetDeactivate() {
    super.mvcWidgetDeactivate();
    onDeactivate?.call();
  }
}

class TestWidgetServiceWithDispose with DependencyInjectionService, MvcWidgetService {
  TestWidgetServiceWithDispose({required this.onDispose});

  final VoidCallback onDispose;

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}

class ServiceCounterState {
  ServiceCounterState(this.count);
  int count;
}

class TestWidgetServiceWithState with DependencyInjectionService, MvcWidgetService {
  late final MvcWidgetScope widgetScope = getService<MvcWidgetScope>();

  void initializeState() {
    widgetScope.createState(ServiceCounterState(0));
  }

  void increment() {
    widgetScope.setState<ServiceCounterState>((state) => state.count++);
  }
}
