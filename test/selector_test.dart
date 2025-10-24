import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Selector (querySelector)', () {
    group('Query by Type', () {
      testWidgets('querySelectorAll finds widgets by type', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_TypeSelectorController, void>(
                create: _TypeSelectorController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Item A: 0'), findsOneWidget);
        expect(find.text('Item B: 0'), findsOneWidget);
        expect(find.text('Item C: 0'), findsOneWidget);

        final context = tester.element(find.byType(Scaffold));
        final controller = context.getService<_TypeSelectorController>();

        controller.incrementAll();
        await tester.pumpAndSettle();

        // All items were updated
        expect(find.text('Item A: 1'), findsOneWidget);
        expect(find.text('Item B: 1'), findsOneWidget);
        expect(find.text('Item C: 1'), findsOneWidget);
      });

      testWidgets('querySelector finds first widget by type', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_TypeSelectorController, void>(
                create: _TypeSelectorController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Scaffold));
        final controller = context.getService<_TypeSelectorController>();

        controller.incrementFirst();
        await tester.pumpAndSettle();

        // Only first item was updated
        expect(find.text('Item A: 1'), findsOneWidget);
        expect(find.text('Item B: 0'), findsOneWidget);
        expect(find.text('Item C: 0'), findsOneWidget);
      });
    });

    group('Query by ID', () {
      testWidgets('querySelector finds widget by id', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_IdSelectorController, void>(
                create: _IdSelectorController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Scaffold));
        final controller = context.getService<_IdSelectorController>();

        controller.incrementItemById('item-b');
        await tester.pumpAndSettle();

        // Only item-b was updated
        expect(find.text('Item A: 0'), findsOneWidget);
        expect(find.text('Item B: 1'), findsOneWidget);
        expect(find.text('Item C: 0'), findsOneWidget);
      });
    });

    group('Query by Class', () {
      testWidgets('querySelectorAll finds widgets by class', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_ClassSelectorController, void>(
                create: _ClassSelectorController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Scaffold));
        final controller = context.getService<_ClassSelectorController>();

        controller.incrementHighlighted();
        await tester.pumpAndSettle();

        // Only items with 'highlight' class were updated
        expect(find.text('Item A: 1'), findsOneWidget);
        expect(find.text('Item B: 0'), findsOneWidget);
        expect(find.text('Item C: 1'), findsOneWidget);
      });
    });

    group('Selector Breaker', () {
      testWidgets('isSelectorBreaker stops query propagation', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_BreakerTestController, void>(
                create: _BreakerTestController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Scaffold));
        final controller = context.getService<_BreakerTestController>();

        // Try to update all items from root
        controller.incrementAll();
        await tester.pumpAndSettle();

        // Only items outside breaker are updated
        expect(find.text('Outside 1: 1'), findsOneWidget);
        expect(find.text('Outside 2: 1'), findsOneWidget);
        expect(find.text('Inside: 0'), findsOneWidget);
      });

      testWidgets('ignoreSelectorBreaker bypasses breaker', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_BreakerTestController, void>(
                create: _BreakerTestController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(Scaffold));
        final controller = context.getService<_BreakerTestController>();

        controller.incrementAllIgnoringBreaker();
        await tester.pumpAndSettle();

        // All items updated, even inside breaker
        expect(find.text('Outside 1: 1'), findsOneWidget);
        expect(find.text('Outside 2: 1'), findsOneWidget);
        expect(find.text('Inside: 1'), findsOneWidget);
      });
    });

    group('MvcWidgetScope Methods', () {
      testWidgets('update() method rebuilds widget', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_UpdaterTestController, void>(
                create: _UpdaterTestController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Counter: 0'), findsOneWidget);

        final context = tester.element(find.text('Counter: 0'));
        final controller = context.getService<_UpdaterTestController>();

        controller.incrementViaSelector();
        await tester.pumpAndSettle();

        expect(find.text('Counter: 1'), findsOneWidget);
      });
    });
  });
}

// Type Selector Test
class _TypeSelectorController extends MvcController<void> {
  final Map<String, int> _counters = {
    'A': 0,
    'B': 0,
    'C': 0,
  };

  void incrementAll() {
    for (final key in _counters.keys) {
      _counters[key] = _counters[key]! + 1;
    }
    widgetScope.querySelectorAll<_CounterWidget>().update();
  }

  void incrementFirst() {
    _counters['A'] = _counters['A']! + 1;
    widgetScope.querySelector<_CounterWidget>()?.update();
  }

  int getCounter(String label) => _counters[label] ?? 0;

  @override
  MvcView view() => _TypeSelectorView();
}

class _TypeSelectorView extends MvcView<_TypeSelectorController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          _CounterWidget(label: 'A', controller: controller),
          _CounterWidget(label: 'B', controller: controller),
          _CounterWidget(label: 'C', controller: controller),
        ],
      ),
    );
  }
}

// ID Selector Test
class _IdSelectorController extends MvcController<void> {
  final Map<String, int> _counters = {
    'A': 0,
    'B': 0,
    'C': 0,
  };

  void incrementItemById(String id) {
    final label = id.split('-').last.toUpperCase();
    _counters[label] = _counters[label]! + 1;
    widgetScope.querySelector('#$id')?.update();
  }

  int getCounter(String label) => _counters[label] ?? 0;

  @override
  MvcView view() => _IdSelectorView();
}

class _IdSelectorView extends MvcView<_IdSelectorController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          _CounterWidget(id: 'item-a', label: 'A', controller: controller),
          _CounterWidget(id: 'item-b', label: 'B', controller: controller),
          _CounterWidget(id: 'item-c', label: 'C', controller: controller),
        ],
      ),
    );
  }
}

// Class Selector Test
class _ClassSelectorController extends MvcController<void> {
  final Map<String, int> _counters = {
    'A': 0,
    'B': 0,
    'C': 0,
  };

  void incrementHighlighted() {
    _counters['A'] = _counters['A']! + 1;
    _counters['C'] = _counters['C']! + 1;
    widgetScope.querySelectorAll('.highlight').update();
  }

  int getCounter(String label) => _counters[label] ?? 0;

  @override
  MvcView view() => _ClassSelectorView();
}

class _ClassSelectorView extends MvcView<_ClassSelectorController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          _CounterWidget(label: 'A', classes: const ['highlight'], controller: controller),
          _CounterWidget(label: 'B', controller: controller),
          _CounterWidget(label: 'C', classes: const ['highlight'], controller: controller),
        ],
      ),
    );
  }
}

// Common Counter Widget - controller-managed state
class _CounterWidget extends MvcStatelessWidget {
  const _CounterWidget({super.id, super.classes, required this.label, required this.controller});

  final String label;
  final dynamic controller; // Could be any of the controllers

  @override
  Widget build(BuildContext context) {
    final count = controller.getCounter(label);
    return Text('Item $label: $count');
  }
}

// Breaker Test
class _BreakerTestController extends MvcController<void> {
  final Map<String, int> _counters = {
    'outside-1': 0,
    'outside-2': 0,
    'inside': 0,
  };

  void incrementAll() {
    for (final key in _counters.keys) {
      _counters[key] = _counters[key]! + 1;
    }
    widgetScope.querySelectorAll<_BreakerCounterWidget>().update();
  }

  void incrementAllIgnoringBreaker() {
    for (final key in _counters.keys) {
      _counters[key] = _counters[key]! + 1;
    }
    widgetScope.querySelectorAll<_BreakerCounterWidget>(null, true).update();
  }

  int getCounter(String id) => _counters[id] ?? 0;

  @override
  MvcView view() => _BreakerTestView();
}

class _BreakerTestView extends MvcView<_BreakerTestController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          _BreakerCounterWidget(id: 'outside-1', label: 'Outside 1', controller: controller),
          _BreakerCounterWidget(id: 'outside-2', label: 'Outside 2', controller: controller),
          MvcSelectorBreaker(
            child: _BreakerCounterWidget(id: 'inside', label: 'Inside', controller: controller),
          ),
        ],
      ),
    );
  }
}

class _BreakerCounterWidget extends MvcStatelessWidget {
  const _BreakerCounterWidget({super.id, required this.label, required this.controller});

  final String label;
  final _BreakerTestController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.getCounter(id!);
    return Text('$label: $count');
  }
}

// Updater Test
class _UpdaterTestController extends MvcController<void> {
  int _count = 0;

  void incrementViaSelector() {
    _count++;
    widgetScope.querySelector<_CounterDisplay>()?.update();
  }

  int get count => _count;

  @override
  MvcView view() => _UpdaterTestView();
}

class _UpdaterTestView extends MvcView<_UpdaterTestController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: _CounterDisplay(controller: controller),
    );
  }
}

class _CounterDisplay extends MvcStatelessWidget {
  const _CounterDisplay({required this.controller});

  final _UpdaterTestController controller;

  @override
  Widget build(BuildContext context) {
    return Text('Counter: ${controller.count}');
  }
}
