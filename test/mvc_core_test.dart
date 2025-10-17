import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MVC Core Components', () {
    group('Mvc Widget and Controller Lifecycle', () {
      testWidgets('creates controller and initializes it', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_LifecycleController, int>(
                create: _LifecycleController.new,
                model: 42,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify view is built
        expect(find.text('Model: 42'), findsOneWidget);

        // Access controller through context
        final context = tester.element(find.text('Model: 42'));
        final controller = context.getMvcService<_LifecycleController>();

        // Verify lifecycle methods were called
        expect(controller.initCalled, isTrue);
        expect(controller.model, equals(42));
      });

      testWidgets('calls didUpdateModel when model changes', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_LifecycleController, int>(
                create: _LifecycleController.new,
                model: 10,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.text('Model: 10'));
        final controller = context.getMvcService<_LifecycleController>();

        expect(controller.didUpdateModelCalled, isFalse);

        // Update model
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_LifecycleController, int>(
                create: _LifecycleController.new,
                model: 20,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.didUpdateModelCalled, isTrue);
        expect(controller.oldModel, equals(10));
        expect(find.text('Model: 20'), findsOneWidget);
      });

      testWidgets('update() method rebuilds view', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_CounterController, void>(
                create: _CounterController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Count: 0'), findsOneWidget);

        final context = tester.element(find.text('Count: 0'));
        final controller = context.getMvcService<_CounterController>();

        controller.increment();
        await tester.pumpAndSettle();

        expect(find.text('Count: 1'), findsOneWidget);
      });
    });

    group('MvcView', () {
      testWidgets('has access to controller', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_CounterController, void>(
                create: _CounterController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // View successfully accessed controller to display count
        expect(find.text('Count: 0'), findsOneWidget);
      });

      testWidgets('can trigger controller methods from UI', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_InteractiveController, void>(
                create: _InteractiveController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Value: 0'), findsOneWidget);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.text('Value: 1'), findsOneWidget);
      });
    });

    group('Controller without create parameter', () {
      testWidgets('gets controller from dependency injection', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MvcApp(
              child: MvcDependencyProvider(
                provider: (collection) {
                  collection.addController<_CounterController>(
                    (_) => _CounterController(),
                  );
                },
                child: const Mvc<_CounterController, void>(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Count: 0'), findsOneWidget);

        final context = tester.element(find.text('Count: 0'));
        final controller = context.getMvcService<_CounterController>();

        controller.increment();
        await tester.pumpAndSettle();

        expect(find.text('Count: 1'), findsOneWidget);
      });
    });
  });
}

// Test Controllers and Views
class _LifecycleController extends MvcController<int> {
  bool initCalled = false;
  bool didUpdateModelCalled = false;
  int? oldModel;

  @override
  void init() {
    initCalled = true;
  }

  @override
  void didUpdateModel(int old) {
    didUpdateModelCalled = true;
    oldModel = old;
  }

  @override
  MvcView view() => _LifecycleView();
}

class _LifecycleView extends MvcView<_LifecycleController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Text('Model: ${controller.model}'),
    );
  }
}

class _CounterController extends MvcController<void> {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    update();
  }

  @override
  MvcView view() => _CounterView();
}

class _CounterView extends MvcView<_CounterController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Text('Count: ${controller.count}'),
    );
  }
}

class _InteractiveController extends MvcController<void> {
  int _value = 0;
  int get value => _value;

  void incrementValue() {
    _value++;
    update();
  }

  @override
  MvcView view() => _InteractiveView();
}

class _InteractiveView extends MvcView<_InteractiveController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          Text('Value: ${controller.value}'),
          ElevatedButton(
            onPressed: controller.incrementValue,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
