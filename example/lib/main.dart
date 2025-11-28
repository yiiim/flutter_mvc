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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MvcApp(
        child: Mvc(
          create: () => CounterController(),
        ),
      ),
    );
  }
}

class CounterController extends MvcController<void> {
  @override
  void init() {
    stateScope.createState(CounterState(0));
  }

  @override
  MvcView view() {
    return CounterView();
  }

  void reset() {
    stateScope.setState(
      (CounterState state) {
        state.count = 0;
      },
    );
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
                  onPressed: controller.reset,
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
