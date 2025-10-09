# Depend on Objects

You can make individual Widgets depend on specific types of objects, triggering Widget rebuilds through object updates.

## Quick Start

Here's a simple counter example that shows how to use objects to update Widgets.

```dart
class CounterService with MvcDependableObject {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyAllDependents();
  }
}

void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: MvcDependencyProvider(
          provider: (collection) {
            collection.addSingleton<CounterService>((_) => CounterService());
          },
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  final counterService = context.dependOnMvcServiceOfExactType<CounterService>();
                  return Text(
                    '${counterService.count}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton(
                  onPressed: () {
                    context.getMvcService<CounterService>().increment();
                  },
                  tooltip: 'Increment',
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
```

You need to pay attention to the type when injecting dependencies, usually you should inject singletons.