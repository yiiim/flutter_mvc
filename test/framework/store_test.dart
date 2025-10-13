import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

// Test model classes
class CounterState {
  CounterState(this.count);
  int count;

  @override
  bool operator ==(Object other) => other is CounterState && other.count == count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => 'CounterState($count)';
}

class UserState {
  UserState({required this.name, required this.age});
  String name;
  int age;

  @override
  bool operator ==(Object other) => other is UserState && other.name == name && other.age == age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;

  @override
  String toString() => 'UserState($name, $age)';
}

class ComplexState {
  ComplexState({required this.data, required this.metadata});
  Map<String, dynamic> data;
  Map<String, String> metadata;

  @override
  String toString() => 'ComplexState($data, $metadata)';
}

class CustomStore<T extends Object> extends MvcRawStore<T> {
  CustomStore(super.state);

  bool customNotificationCalled = false;
  int updateCount = 0;

  @override
  void setState([void Function(T state)? set]) {
    super.setState(set);
    customNotificationCalled = true;
    updateCount++;
  }
}

// Test service class for state initialization
class TestService with DependencyInjectionService {
  TestService({
    this.initCounterState,
    this.initUserState,
    this.initComplexState,
    this.onInitialize,
  });
  final CounterState? initCounterState;
  final UserState? initUserState;
  final ComplexState? initComplexState;
  final void Function()? onInitialize;
  late final MvcWidgetScope widgetScope;

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    widgetScope = getService<MvcWidgetScope>();
    if (initCounterState != null) {
      widgetScope.createState<CounterState>(initCounterState!);
    }
    if (initUserState != null) {
      widgetScope.createState<UserState>(initUserState!);
    }
    if (initComplexState != null) {
      widgetScope.createState<ComplexState>(initComplexState!);
    }
    onInitialize?.call();
  }
}

class StateTestWidget<T> extends MvcStatelessWidget {
  const StateTestWidget({
    super.key,
    required this.onStateChanged,
    this.selector,
    this.initialValue,
  });

  final void Function(T value) onStateChanged;
  final T Function(CounterState)? selector;
  final int? initialValue;

  @override
  Widget build(BuildContext context) {
    final value = context.stateAccessor.useState(
      selector ?? (CounterState state) => state as T,
      initializer: () => CounterState(initialValue ?? 0),
    );
    onStateChanged(value);

    return Text('StateTest: $value', textDirection: TextDirection.ltr);
  }
}

// Additional helper widget
class SimpleTestWidget extends MvcStatelessWidget {
  const SimpleTestWidget({
    super.key,
    required this.onBuild,
  });

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Text('Simple Widget', textDirection: TextDirection.ltr);
  }
}

// Test widget service class
class TestWidgetService with DependencyInjectionService, MvcWidgetService {
  bool serviceActivated = false;
  bool serviceDeactivated = false;
  bool serviceInitialized = false;

  @override
  void mvcWidgetActivate() {
    super.mvcWidgetActivate();
    serviceActivated = true;
  }

  @override
  void mvcWidgetDeactivate() {
    super.mvcWidgetDeactivate();
    serviceDeactivated = true;
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() async {
    await super.dependencyInjectionServiceInitialize();
    serviceInitialized = true;
  }

  void triggerUpdate() {
    update(() {
      // Trigger widget update
    });
  }
}

void main() {
  group('Core Store Tests', () {
    test('should initialize MvcRawStore with correct state', () {
      final initialState = CounterState(42);
      final store = MvcRawStore<CounterState>(initialState);

      expect(store.state, equals(initialState));
      expect(store.state.count, equals(42));
    });

    test('should update store state correctly', () {
      final store = MvcRawStore<CounterState>(CounterState(10));

      store.setState((state) => state.count = 20);

      expect(store.state.count, equals(20));
    });

    test('should work with custom store implementation', () {
      final customStore = CustomStore<CounterState>(CounterState(5));

      customStore.setState((state) => state.count = 15);

      expect(customStore.state.count, equals(15));
      expect(customStore.customNotificationCalled, isTrue);
      expect(customStore.updateCount, equals(1));
    });
  });

  group('State Management Tests', () {
    testWidgets('should create and manage states through service', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => TestService(
                initCounterState: CounterState(10),
                initUserState: UserState(name: 'Alice', age: 30),
              ),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final counterValue = context.stateAccessor.useState<CounterState, int>((state) => state.count);
              final userName = context.stateAccessor.useState<UserState, String>((state) => state.name);

              return Text('States: $counterValue, $userName', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('States: 10, Alice'), findsOneWidget);
    });

    testWidgets('should retrieve stores correctly', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => TestService(initCounterState: CounterState(25)),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();
              final store = scope.getStore<CounterState>();
              final hasStore = store != null;
              final storeValue = store?.state.count ?? 0;

              return Text('Store: $hasStore, Value: $storeValue', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Store: true, Value: 25'), findsOneWidget);
    });

    testWidgets('should handle state updates and rebuilds', (tester) async {
      late TestService testService;
      Widget buildStateWidget() {
        return MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => testService = TestService(
                initCounterState: CounterState(500),
              ),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final currentValue = context.stateAccessor.useState<CounterState, int>((state) => state.count);
              return Text('Text: $currentValue', textDirection: TextDirection.ltr);
            },
          ),
        );
      }

      await tester.pumpWidget(buildStateWidget());
      expect(find.text('Text: 500'), findsOneWidget);

      // Update state
      testService.widgetScope.setState<CounterState>((state) => state.count = 600);
      await tester.pump();
      expect(find.text('Text: 600'), findsOneWidget);
    });

    testWidgets('should work with multiple state types in same scope', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => TestService(
                initCounterState: CounterState(200),
                initUserState: UserState(name: 'Bob', age: 25),
              ),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final counterValue = context.stateAccessor.useState<CounterState, int>((state) => state.count);
              final userName = context.stateAccessor.useState<UserState, String>((state) => state.name);
              final userAge = context.stateAccessor.useState<UserState, int>((state) => state.age);

              return Text('Multi: $counterValue, $userName-$userAge', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Multi: 200, Bob-25'), findsOneWidget);
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('should work with useState and selector', (tester) async {
      dynamic capturedValue;

      await tester.pumpWidget(
        MvcApp(
          child: StateTestWidget(
            initialValue: 50,
            selector: (state) => state.count,
            onStateChanged: (value) => capturedValue = value,
          ),
        ),
      );

      expect(capturedValue, equals(50));
    });

    testWidgets('should work with useState and state updates', (tester) async {
      dynamic capturedValue1;
      dynamic capturedValue2;

      await tester.pumpWidget(
        MvcApp(
          child: StateTestWidget(
            initialValue: 50,
            selector: (state) => state.count,
            onStateChanged: (value) => capturedValue1 = value,
          ),
        ),
      );

      expect(capturedValue1, equals(50));

      // Update the widget to trigger state change
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              // Update existing state
              scope.setState<CounterState>((state) => state.count = 75);

              return StateTestWidget(
                selector: (state) => state.count,
                onStateChanged: (value) => capturedValue2 = value,
              );
            },
          ),
        ),
      );

      expect(capturedValue2, equals(75));
    });

    testWidgets('should work with manual state management', (tester) async {
      int? capturedValue;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              if (scope.getStore<CounterState>() == null) {
                scope.createState<CounterState>(CounterState(15));
              }

              final store = scope.getStore<CounterState>()!;
              capturedValue = store.state.count;

              return Text('Value: $capturedValue', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(capturedValue, equals(15));
      expect(find.text('Value: 15'), findsOneWidget);
    });
  });

  group('State Scope Tests', () {
    testWidgets('should work with MvcStateScope', (tester) async {
      bool builderCalled = false;

      await tester.pumpWidget(
        MvcApp(
          child: MvcStateScope(
            builder: (context) {
              builderCalled = true;
              return const Text('State Scope', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(builderCalled, isTrue);
      expect(find.text('State Scope'), findsOneWidget);
    });

    testWidgets('should handle nested state scopes', (tester) async {
      CounterState? parentState;
      CounterState? childState;

      await tester.pumpWidget(
        MvcApp(
          child: MvcStateScope(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();
              parentState = scope.createState<CounterState>(CounterState(300)).state;

              return MvcStateScope(
                builder: (context) {
                  final childScope = context.getMvcService<MvcWidgetScope>();
                  childState = childScope.createState<CounterState>(CounterState(400)).state;

                  return Text('Nested: ${parentState?.count}, ${childState?.count}', textDirection: TextDirection.ltr);
                },
              );
            },
          ),
        ),
      );

      expect(parentState?.count, equals(300));
      expect(childState?.count, equals(400));
      expect(find.text('Nested: 300, 400'), findsOneWidget);
    });
  });

  group('Custom Store Tests', () {
    testWidgets('should work with custom store types', (tester) async {
      CustomStore<CounterState>? customStore;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              customStore = scope.createStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                CounterState(60),
                initializer: (state) => CustomStore<CounterState>(state),
              );

              return Text('Custom: ${customStore?.state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(customStore, isA<CustomStore<CounterState>>());
      expect(customStore?.state.count, equals(60));
      expect(find.text('Custom: 60'), findsOneWidget);
    });

    testWidgets('should retrieve stores by exact type', (tester) async {
      CustomStore<CounterState>? retrievedCustomStore;
      MvcRawStore<CounterState>? retrievedGenericStore;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              // Create custom store
              scope.createStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                CounterState(80),
                initializer: (state) => CustomStore<CounterState>(state),
              );

              // Retrieve by exact type
              retrievedCustomStore = scope.getStoreOfExactType<CounterState, CustomStore<CounterState>>();

              // Try to retrieve as generic type - CustomStore extends MvcRawStore, so this should work
              retrievedGenericStore = scope.getStore<CounterState>();

              return Text('Retrieved Custom: ${retrievedCustomStore?.state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(retrievedCustomStore, isA<CustomStore<CounterState>>());
      expect(retrievedCustomStore?.state.count, equals(80));
      expect(retrievedGenericStore, isA<CustomStore<CounterState>>());
      expect(find.text('Retrieved Custom: 80'), findsOneWidget);
    });

    testWidgets('should handle setState with exact store type', (tester) async {
      CustomStore<CounterState>? customStore;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              if (scope.getStoreOfExactType<CounterState, CustomStore<CounterState>>() == null) {
                scope.createStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                  CounterState(90),
                  initializer: (state) => CustomStore<CounterState>(state),
                );
              }

              // Use setStateOfExactStoreType
              scope.setStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                (state) => state.count = 95,
              );

              customStore = scope.getStoreOfExactType<CounterState, CustomStore<CounterState>>();

              return Text('Custom setState: ${customStore?.state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(customStore?.state.count, equals(95));
      expect(find.text('Custom setState: 95'), findsOneWidget);
    });

    testWidgets('should handle custom store behavior tracking', (tester) async {
      CustomStore<CounterState>? customStore;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              if (scope.getStoreOfExactType<CounterState, CustomStore<CounterState>>() == null) {
                scope.createStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                  CounterState(10),
                  initializer: (state) => CustomStore<CounterState>(state),
                );
              }

              customStore = scope.getStoreOfExactType<CounterState, CustomStore<CounterState>>();

              // Trigger setState multiple times
              scope.setStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                (state) => state.count += 1,
              );
              scope.setStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                (state) => state.count += 2,
              );

              return Text('Custom Track: ${customStore?.state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(customStore?.updateCount, greaterThan(1));
      expect(customStore?.state.count, greaterThan(10));
    });

    testWidgets('should handle multiple different store types', (tester) async {
      MvcRawStore<CounterState>? counterStore;
      MvcRawStore<UserState>? userStore;
      CustomStore<ComplexState>? complexStore;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              // Create different store types
              counterStore = scope.createStateOfExactStoreType<CounterState, MvcRawStore<CounterState>>(CounterState(100));

              userStore = scope.createStateOfExactStoreType<UserState, MvcRawStore<UserState>>(UserState(name: 'Multi', age: 99));

              complexStore = scope.createStateOfExactStoreType<ComplexState, CustomStore<ComplexState>>(
                ComplexState(data: {'test': true}, metadata: {'type': 'multi'}),
                initializer: (state) => CustomStore<ComplexState>(state),
              );

              return Text('Multi: ${counterStore?.state.count}, ${userStore?.state.name}, ${complexStore?.state.data['test']}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(counterStore?.state.count, equals(100));
      expect(userStore?.state.name, equals('Multi'));
      expect(complexStore?.state.data['test'], isTrue);
      expect(find.text('Multi: 100, Multi, true'), findsOneWidget);
    });
  });

  testWidgets('should handle complex state with maps', (tester) async {
    await tester.pumpWidget(
      MvcApp(
        serviceProviderBuilder: (collection) {
          collection.add<TestService>(
            (_) => TestService(
              initComplexState: ComplexState(
                data: {'key1': 'value1', 'key2': 42},
                metadata: {'author': 'test', 'version': '1.0'},
              ),
            ),
            initializeWhenServiceProviderBuilt: true,
          );
        },
        child: Builder(
          builder: (context) {
            final complexValue = context.stateAccessor.useState<ComplexState, String>(
              (state) => state.data['key1']?.toString() ?? '',
            );
            final complexData = context.stateAccessor.useState<ComplexState, Map<String, dynamic>>(
              (state) => state.data,
            );
            final complexMetadata = context.stateAccessor.useState<ComplexState, Map<String, String>>(
              (state) => state.metadata,
            );

            return Column(
              children: [
                Text('Complex: $complexValue', textDirection: TextDirection.ltr),
                Text('Data key2: ${complexData['key2']}', textDirection: TextDirection.ltr),
                Text('Author: ${complexMetadata['author']}', textDirection: TextDirection.ltr),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('Complex: value1'), findsOneWidget);
    expect(find.text('Data key2: 42'), findsOneWidget);
    expect(find.text('Author: test'), findsOneWidget);
  });

  testWidgets('should work with complex state updates', (tester) async {
    await tester.pumpWidget(
      MvcApp(
        serviceProviderBuilder: (collection) {
          collection.add<TestService>(
            (_) => TestService(
              initComplexState: ComplexState(
                data: {'counter': 0, 'name': 'initial'},
                metadata: {'version': '1.0'},
              ),
            ),
            initializeWhenServiceProviderBuilt: true,
          );
        },
        child: Builder(
          builder: (context) {
            final counterValue = context.stateAccessor.useState<ComplexState, int>(
              (state) => state.data['counter'] as int,
            );
            final nameValue = context.stateAccessor.useState<ComplexState, String>(
              (state) => state.data['name'] as String,
            );
            final versionValue = context.stateAccessor.useState<ComplexState, String>(
              (state) => state.metadata['version'] as String,
            );

            return Column(
              children: [
                Text('Complex: $counterValue', textDirection: TextDirection.ltr),
                Text('Name: $nameValue', textDirection: TextDirection.ltr),
                Text('Version: $versionValue', textDirection: TextDirection.ltr),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('Complex: 0'), findsOneWidget);
    expect(find.text('Name: initial'), findsOneWidget);
    expect(find.text('Version: 1.0'), findsOneWidget);
  });

  testWidgets('should handle edge cases in state management', (tester) async {
    late TestService testService;

    // Initial widget with zero value
    await tester.pumpWidget(
      MvcApp(
        serviceProviderBuilder: (collection) {
          collection.add<TestService>(
            (_) => testService = TestService(
              initCounterState: CounterState(0),
            ),
            initializeWhenServiceProviderBuilt: true,
          );
        },
        child: Builder(
          builder: (context) {
            final initialValue = context.stateAccessor.useState<CounterState, int>((state) => state.count);
            return Text('Initial: $initialValue', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    expect(find.text('Initial: 0'), findsOneWidget);

    testService.widgetScope.setState<CounterState>((state) => state.count = -50);

    await tester.pump();

    expect(find.text('Initial: -50'), findsOneWidget);
  });

  group('Dependency Groups Tests', () {
    testWidgets('should handle dependency groups correctly', (tester) async {
      late TestService testService;

      await tester.pumpWidget(
        MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => testService = TestService(
                initCounterState: CounterState(100),
                initUserState: UserState(name: 'GroupTest', age: 30),
              ),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final counterValue = context.stateAccessor.useState<CounterState, int>((state) => state.count);
              final userName = context.stateAccessor.useState<UserState, String>((state) => state.name);

              return Text('Groups: $counterValue, $userName', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Groups: 100, GroupTest'), findsOneWidget);

      // Test dependency groups functionality
      final counterStore = testService.widgetScope.getStore<CounterState>()!;
      final userStore = testService.widgetScope.getStore<UserState>()!;

      // Check if dependency groups exist
      expect(counterStore.hasDependencyGroup(CounterState), isTrue);
      expect(userStore.hasDependencyGroup(UserState), isTrue);

      // Check dependents count in groups
      expect(counterStore.getDependentsCountInGroup(CounterState), greaterThan(0));
      expect(userStore.getDependentsCountInGroup(UserState), greaterThan(0));

      // Get all dependency groups
      expect(counterStore.dependencyGroups, contains(CounterState));
      expect(userStore.dependencyGroups, contains(UserState));
    });

    testWidgets('should clear dependency groups correctly', (tester) async {
      late TestService testService;

      await tester.pumpWidget(
        MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => testService = TestService(
                initCounterState: CounterState(200),
              ),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final counterValue = context.stateAccessor.useState((CounterState state) => state.count);
              return Text('Clear Test: $counterValue', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Clear Test: 200'), findsOneWidget);

      final counterStore = testService.widgetScope.getStore<CounterState>()!;

      // Verify group exists before clearing
      expect(counterStore.hasDependencyGroup(CounterState), isTrue);

      // Clear the dependency group
      counterStore.clearDependencyGroup(CounterState);

      // Verify group is cleared
      expect(counterStore.getDependentsCountInGroup(CounterState), equals(0));
    });
  });

  group('Store Repository Tests', () {
    testWidgets('should handle store repository correctly', (tester) async {
      late TestService testService;

      await tester.pumpWidget(
        MvcApp(
          serviceProviderBuilder: (collection) {
            collection.add<TestService>(
              (_) => testService = TestService(
                initCounterState: CounterState(300),
                initUserState: UserState(name: 'RepoTest', age: 25),
              ),
              initializeWhenServiceProviderBuilt: true,
            );
          },
          child: Builder(
            builder: (context) {
              final counterValue = context.stateAccessor.useState<CounterState, int>((state) => state.count);
              final userName = context.stateAccessor.useState<UserState, String>((state) => state.name);
              return Text('Repository: $counterValue, $userName', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Repository: 300, RepoTest'), findsOneWidget);

      // Test store retrieval
      final counterStore = testService.widgetScope.getStore<CounterState>();
      final userStore = testService.widgetScope.getStore<UserState>();

      expect(counterStore, isNotNull);
      expect(userStore, isNotNull);
      expect(counterStore!.state.count, equals(300));
      expect(userStore!.state.name, equals('RepoTest'));
    });

    testWidgets('should handle exact store type retrieval', (tester) async {
      CustomStore<CounterState>? customStore;

      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final scope = context.getMvcService<MvcWidgetScope>();

              // Create custom store
              customStore = scope.createStateOfExactStoreType<CounterState, CustomStore<CounterState>>(
                CounterState(400),
                initializer: (state) => CustomStore<CounterState>(state),
              );

              // Test exact type retrieval
              final retrievedCustomStore = scope.getStoreOfExactType<CounterState, CustomStore<CounterState>>();
              final genericStore = scope.getStore<CounterState>();

              expect(retrievedCustomStore, isA<CustomStore<CounterState>>());
              expect(genericStore, isA<CustomStore<CounterState>>());
              expect(retrievedCustomStore, equals(customStore));
              expect(genericStore, equals(customStore));

              return Text('Exact Type: ${customStore?.state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Exact Type: 400'), findsOneWidget);
      expect(customStore, isA<CustomStore<CounterState>>());
    });
  });

  group('MvcStateAccessor Advanced Tests', () {
    testWidgets('should work with useStateOfExactRawStoreType', (tester) async {
      late final MvcRawStore<CounterState> rawStore;
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final value = context.stateAccessor.useStateOfExactRawStoreType<CounterState, int, MvcRawStore<CounterState>>(
                (state) => state.count,
                initializer: () => CounterState(700),
                storeInitializer: (state) => rawStore = MvcRawStore<CounterState>(state),
              );
              return Text('Exact Store: $value', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Exact Store: 700'), findsOneWidget);
      expect(rawStore.state.count, equals(700));
      rawStore.setState((state) => state.count = 750);
      await tester.pump();
      expect(find.text('Exact Store: 750'), findsOneWidget);
    });

    testWidgets('should work with custom store initializer', (tester) async {
      late final CustomStore<CounterState> customStore;
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final value = context.stateAccessor.useStateOfExactRawStoreType<CounterState, int, CustomStore<CounterState>>(
                (state) => state.count,
                initializer: () => CounterState(800),
                storeInitializer: (state) => customStore = CustomStore<CounterState>(state),
              );
              return Text('Custom Init: $value', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Custom Init: 800'), findsOneWidget);
      expect(customStore.state.count, equals(800));
      customStore.setState((state) => state.count = 850);
      await tester.pump();
      expect(find.text('Custom Init: 850'), findsOneWidget);
    });

    testWidgets('should work with useStateOfExactRawStore', (tester) async {
      final customStore = CustomStore<CounterState>(CounterState(900));
      await tester.pumpWidget(
        MvcApp(
          child: Builder(
            builder: (context) {
              final stateAccessor = context.stateAccessor;

              final value = stateAccessor.useStateOfExactRawStore<CounterState, int, CustomStore<CounterState>>(
                customStore,
                (state) => state.count,
              );
              return Text('Direct Store: $value', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Direct Store: 900'), findsOneWidget);
      customStore.setState((state) => state.count = 950);
      await tester.pump();
      expect(find.text('Direct Store: 950'), findsOneWidget);
    });
  });
}
