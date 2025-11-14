import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class CounterState {
  CounterState(this.count);
  int count;
  String text = "Initial Text";
}

void main() {
  runApp(const MyApp());
}

class CounterService with MvcDependableObject {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    // 3. 当状态改变时，通知所有依赖者
    notifyAllDependents();
  }
}

// UI Widget
class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Get the service instance and establish a dependency
    final counterService = context.getService<CounterService>();
    context.dependOnObject(counterService);

    return Text(
      '${counterService.count}',
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MvcApp(
        child: MvcDependencyProvider(
          provider: (collection) {
            // Note: To ensure multiple widgets share the same instance,
            // it must be injected as a singleton.
            collection.addSingleton<CounterService>((_) => CounterService());
          },
          child: Scaffold(
            body: const Center(
              child: CounterText(), // Use the independent widget
            ),
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton(
                  onPressed: () {
                    // Get the service instance and call the method
                    context.getService<CounterService>().increment();
                  },
                  tooltip: 'Increment',
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CounterController extends MvcController<void> with MvcStatefulService<CounterState> {
  void resetCounter() {
    setState(
      (CounterState state) {
        state.count = 0;
      },
    );
  }

  @override
  MvcView view() {
    return CounterView();
  }

  @override
  CounterState initializeState() {
    return CounterState(0);
  }
}

class IncrementCounterButton extends StatelessWidget {
  const IncrementCounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final stateScope = context.stateScope;
        stateScope.setState(
          (CounterState state) {
            state.count++;
          },
        );
      },
      child: const Text('Increment Counter'),
    );
  }
}

class DecrementCounterButton extends StatelessWidget {
  const DecrementCounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final stateScope = context.stateScope;
        stateScope.setState(
          (CounterState state) {
            state.count--;
          },
        );
      },
      child: const Text('Decrement Counter'),
    );
  }
}

class CounterView extends MvcView<CounterController> {
  @override
  Widget buildView() {
    return Builder(
      builder: (context) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  final count = context.stateAccessor.useState((CounterState state) => state.count);
                  return Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const IncrementCounterButton(),
                const SizedBox(height: 8),
                const DecrementCounterButton(),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.resetCounter,
                  child: const Text('Reset Counter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
