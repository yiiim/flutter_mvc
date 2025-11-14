# Reactive Services (`MvcDependableObject`)

In addition to using `MvcController` and `MvcRawStore` for state management, `flutter_mvc` offers a more lightweight and flexible way for widgets to react to changes: by depending on an observable object.

You can make any Dart class "dependable" by mixing in `MvcDependableObject`. When the state of this object changes, it can notify all widgets that depend on it to rebuild.

This is very useful for creating reusable business logic or state that needs to be shared and synchronized across multiple, unrelated widgets.

## Core Concepts

1.  **`MvcDependableObject`**:
    A `mixin` that adds dependency tracking and notification capabilities to your class.

    - `notifyAllDependents()`: Notifies all widgets depending on this object to rebuild.

2.  **`context.dependOnObject(object)`**:
    This is an extension method on `BuildContext`. When you call it within a widget's `build` method, it registers the current widget as a "dependent" of the `object` instance.

When the service instance calls `notifyAllDependents()`, all registered dependents (i.e., the widgets that called `dependOnObject`) will be marked as "needs rebuild," thus automatically updating the UI.

## Quick Start

Here is a simple counter example that demonstrates how to use `MvcDependableObject` to update a widget.

```dart
// 1. Create a service class that mixes in MvcDependableObject
class CounterService with MvcDependableObject {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    // 3. When the state changes, notify all dependents
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

void main() {
  runApp(
    MaterialApp(
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
                    context.get<CounterService>().increment();
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

### Important Notes

- **Inject as a Singleton**: To ensure that different parts of your application access the same `CounterService` instance, you should register it as a singleton (`addSingleton`). If you register it as transient (`add`) or scoped (`addScoped`), you might get different instances each time, and `notifyAllDependents()` will not correctly notify all expected widgets.
