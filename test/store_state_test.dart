import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Store State Management', () {
    group('State Creation and Updates', () {
      testWidgets('creates state with initializer', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: _StateCreationWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // State was created with initializer
        expect(find.text('Count: 0'), findsOneWidget);
      });

      testWidgets('useState subscribes to state changes', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: _StateUpdateWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Count: 0'), findsOneWidget);

        // Trigger state update
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // UI updated after state change
        expect(find.text('Count: 1'), findsOneWidget);
      });

      testWidgets('only rebuilds widgets that depend on changed state', (tester) async {
        int build1Count = 0;
        int build2Count = 0;

        await tester.pumpWidget(
          MvcApp(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        build1Count++;
                        final count = context.stateAccessor.useState(
                          (_CounterState state) => state.count,
                          initializer: () => _CounterState(0),
                        );
                        return Text('Counter: $count');
                      },
                    ),
                    Builder(
                      builder: (context) {
                        build2Count++;
                        return const Text('Static');
                      },
                    ),
                    Builder(
                      builder: (context) {
                        return ElevatedButton(
                          onPressed: () {
                            final scope = context.getService<MvcStateScope>();
                            scope.setState<_CounterState>((state) {
                              state.count++;
                            });
                          },
                          child: const Text('Increment'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialBuild1 = build1Count;
        final initialBuild2 = build2Count;

        // Update state
        await tester.tap(find.text('Increment'));
        await tester.pumpAndSettle();

        // Only the widget depending on state was rebuilt
        expect(build1Count, greaterThan(initialBuild1));
        expect(build2Count, equals(initialBuild2));
        expect(find.text('Counter: 1'), findsOneWidget);
      });

      testWidgets('selector function limits rebuilds', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: _SelectorTestWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Count: 0'), findsOneWidget);
        expect(find.text('Name: Initial'), findsOneWidget);

        // Update only count
        await tester.tap(find.text('Increment Count'));
        await tester.pumpAndSettle();

        expect(find.text('Count: 1'), findsOneWidget);

        // Update only name
        await tester.tap(find.text('Change Name'));
        await tester.pumpAndSettle();

        expect(find.text('Name: Updated'), findsOneWidget);
      });
    });

    group('State Scope Isolation', () {
      testWidgets('MvcStateScopeBuilder creates isolated scope', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: _ScopeIsolationWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Root: 0'), findsOneWidget);
        expect(find.text('Scoped: 0'), findsOneWidget);

        // Increment root counter
        await tester.tap(find.text('Increment Root'));
        await tester.pumpAndSettle();

        expect(find.text('Root: 1'), findsOneWidget);
        expect(find.text('Scoped: 0'), findsOneWidget);

        // Increment scoped counter
        await tester.tap(find.text('Increment Scoped'));
        await tester.pumpAndSettle();

        expect(find.text('Root: 1'), findsOneWidget);
        expect(find.text('Scoped: 1'), findsOneWidget);
      });
    });

    group('Controller State Management', () {
      testWidgets('controller can create and manage state', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_StateControllerTest, void>(
                create: _StateControllerTest.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Controller Count: 0'), findsOneWidget);

        await tester.tap(find.text('Increment'));
        await tester.pumpAndSettle();

        expect(find.text('Controller Count: 1'), findsOneWidget);
      });
    });
  });
}

// Test State Classes
class _CounterState {
  _CounterState(this.count);
  int count;
}

class _ComplexState {
  _ComplexState(this.count, this.name);
  int count;
  String name;
}

// Test Widgets
class _StateCreationWidget extends StatelessWidget {
  const _StateCreationWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          final count = context.stateAccessor.useState(
            (_CounterState state) => state.count,
            initializer: () => _CounterState(0),
          );
          return Text('Count: $count');
        },
      ),
    );
  }
}

class _StateUpdateWidget extends StatelessWidget {
  const _StateUpdateWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder: (context) {
              final count = context.stateAccessor.useState(
                (_CounterState state) => state.count,
                initializer: () => _CounterState(0),
              );
              return Text('Count: $count');
            },
          ),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  final scope = context.getService<MvcStateScope>();
                  scope.setState<_CounterState>((state) {
                    state.count++;
                  });
                },
                child: const Text('Increment'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectorTestWidget extends StatelessWidget {
  const _SelectorTestWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder: (context) {
              final count = context.stateAccessor.useState(
                (_ComplexState state) => state.count,
                initializer: () => _ComplexState(0, 'Initial'),
              );
              return Text('Count: $count');
            },
          ),
          Builder(
            builder: (context) {
              final name = context.stateAccessor.useState(
                (_ComplexState state) => state.name,
              );
              return Text('Name: $name');
            },
          ),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  final scope = context.getService<MvcStateScope>();
                  scope.setState<_ComplexState>((state) {
                    state.count++;
                  });
                },
                child: const Text('Increment Count'),
              );
            },
          ),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  final scope = context.getService<MvcStateScope>();
                  scope.setState<_ComplexState>((state) {
                    state.name = 'Updated';
                  });
                },
                child: const Text('Change Name'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScopeIsolationWidget extends StatelessWidget {
  const _ScopeIsolationWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder: (context) {
              final count = context.stateAccessor.useState(
                (_CounterState state) => state.count,
                initializer: () => _CounterState(0),
              );
              return Text('Root: $count');
            },
          ),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  final scope = context.getService<MvcStateScope>();
                  scope.setState<_CounterState>((state) {
                    state.count++;
                  });
                },
                child: const Text('Increment Root'),
              );
            },
          ),
          const Expanded(child: _ScopedSection()),
        ],
      ),
    );
  }
}

class _ScopedSection extends StatelessWidget {
  const _ScopedSection();

  @override
  Widget build(BuildContext context) {
    return MvcStateScopeBuilder(
      onStateScopeCreated: (scope) {
        scope.createState(_CounterState(0));
      },
      builder: (context) {
        return Column(
          children: [
            Builder(
              builder: (context) {
                final count = context.stateAccessor.useState(
                  (_CounterState state) => state.count,
                );
                return Text('Scoped: $count');
              },
            ),
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    final scope = context.getService<MvcStateScope>();
                    scope.setState<_CounterState>((state) {
                      state.count++;
                    });
                  },
                  child: const Text('Increment Scoped'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _StateControllerTest extends MvcController<void> {
  @override
  void init() {
    stateScope.createState(_CounterState(0));
  }

  void incrementCounter() {
    stateScope.setState<_CounterState>((state) {
      state.count++;
    });
  }

  @override
  MvcView view() => _StateControllerView();
}

class _StateControllerView extends MvcView<_StateControllerTest> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder: (context) {
              final count = context.stateAccessor.useState(
                (_CounterState state) => state.count,
              );
              return Text('Controller Count: $count');
            },
          ),
          ElevatedButton(
            onPressed: controller.incrementCounter,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
