# State Management (Store)

`flutter_mvc` provides a lightweight, reactive state management mechanism, with `MvcStateScope` and `context.stateAccessor` at its core. This system allows you to create, access, and listen to state anywhere in the widget tree, and automatically rebuild relevant widgets when the state changes.

## Core API: `context.stateAccessor.useState`

This is the most commonly used state management API in `flutter_mvc`. It integrates state creation, retrieval, and listening.

`R useState<T extends Object, R>(R Function(T use) fn, {T Function()? initializer, MvcRawStore<T> Function(T state)? storeInitializer})`

- **Generic `T`**: The type of the state object you want to manage.
- **Generic `R`**: The type of the value you want to extract and listen to from the state.
- **`R Function(T use) fn`**: A function to extract the value you want to listen to from the state object.
- **`initializer` (optional)**: A function to create an instance of the state when it's first requested and doesn't exist.
- **`storeInitializer` (optional)**: A function to customize the initialization logic of the state storage class.

**Example**:

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final (int count, String text) = context.stateAccessor.useState(
      (CounterState state) => (state.count, state.text),
      initializer: () => CounterState(0, ""),
    );
    return Text("MyWidget: count=$count, text=$text");
  }
}
```

This will look for a `CounterState` instance in the state scope of the context. If it doesn't exist, it calls `initializer` to create a new state. Then, it extracts and listens to the `count` and `text` fields. When either of these fields changes, the widget that called `useState` will automatically rebuild.

> You don't have to provide generic arguments; the Dart compiler can usually infer the types `T` and `R` from the passed function.

### How It Works

1.  **Find**: When you call `context.stateAccessor.useState<MyState, R>()`, the framework starts from the current `BuildContext` and looks for a state of type `MyState` in the nearest `MvcStateScope`.
2.  **Create**: If no instance of `MyState` is found in any parent `MvcStateScope`, and you have provided an `initializer` function, the framework calls that function to create a new state instance and stores it in the `MvcStateScope` of the **current** widget.
3.  **Listen**: The widget that calls `useState` is automatically registered as a listener for that state, and it only listens to the fields extracted by `fn`. When these fields change, the widget is marked for rebuilding.
4.  **Return**: Returns the found or newly created state instance.

## Core Class: `MvcStateScope`

`MvcStateScope` represents a state scope. You can create independent state scopes at different positions in the widget tree. All child widgets of a state scope can use the states within that scope. State-related operations are performed on this class, including creating, getting, updating, and deleting states.

```dart
abstract class MvcStateScope {
  /// Creates and registers a new state of type [T].
  /// Throws an error if a state of the same type already exists in the current scope.
  MvcSetState<T> createState<T extends Object>(T state);

  /// Updates a state of type [T].
  /// The [set] function receives the current state and can modify it.
  void setState<T extends Object>([void Function(T state)? set]);

  /// Gets the current state of type [T].
  /// Returns `null` if the state does not exist.
  T? getState<T extends Object>();

  /// Gets the raw store for a state of type [T].
  /// Returns `null` if the store does not exist.
  MvcRawStore<T>? getStore<T extends Object>();

  /// A more specific version of [getStore] that allows specifying the exact store type.
  R? getStoreOfExactType<T extends Object, R extends MvcRawStore<T>>();

  /// Deletes a state of type [T] from the current scope.
  void deleteState<T extends Object>();

  /// Listens to changes in a state of type [T] and returns a value of type [R].
  ///
  /// The [listener] is called whenever the selected part of the state changes.
  /// The [use] function selects the part of the state to listen to.
  R listenState<T extends Object, R>(MvcStateListener listener, [R Function(T state)? use]);

  /// Removes a state listener.
  void removeStateListener<T extends Object>(MvcStateListener listener);
}
```

In `MvcWidgetState`, `MvcController`, or `BuildContext`, you can get the nearest `MvcStateScope` through the `stateScope` property. Alternatively, you can get it through dependency injection using the `MvcStateScope` type. When using dependency injection, be mindful of the scope rules to ensure you get the instance from the correct scope. For dependency injection scope rules, please refer to the [Dependency Injection chapter](./dependency_injection.md#dependency-injection-scope).

For more details, refer to the [State Scope chapter](./scope.md#mvcstatescope).

## Basic Usage

A simple Dart class can serve as a state.

```dart
class CounterState {
  int count = 0;
}
```

### `createStateIfAbsent` and `MvcSetState`

```dart
void main() {
  runApp(
    const MvcApp(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final setState = context.stateScope.createStateIfAbsent<CounterState>(
      () => CounterState(0),
    );
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState((state) => state.count++),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

The `createStateIfAbsent` method creates the state if it doesn't exist and returns an `MvcSetState` method, which can be used to update the state. This approach is suitable for use in a `StatelessWidget`.

### `MvcStatefulService`

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MvcApp(
      child: MvcDependencyProvider(
        child: const MyWidget(),
        provider: (collection) {
          collection.addSingleton(
            (_) => MyStatefulService(),
            initializeWhenServiceProviderBuilt: true,
          );
        },
      ),
    );
  }
}

class MyStatefulService with DependencyInjectionService, MvcStatefulService<CounterState> {
  void increment() {
    setState((state) {
      state.count++;
    });
  }

  @override
  CounterState initializeState() {
    return CounterState(0);
  }
}

class MyWidget extends MvcStatelessWidget {
  const MyWidget({super.key, super.id, super.classes, super.attributes});
  @override
  Widget build(BuildContext context) {
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.getService<MyStatefulService>().increment(),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

`MvcStatefulService` is a way to combine state management with dependency injection. It allows you to create and manage state within a service, and access and modify that state wherever needed through dependency injection.

> The `initializeWhenServiceProviderBuilt` parameter ensures that the service is created and initialized (creating the state) when the widget is built.

> `MvcController` can also be mixed with `MvcStatefulService` to manage state.

> This is the most recommended approach.

### MvcStateScope

You can use `MvcStateScope` directly to manage state, but we generally do not recommend this because it can scatter state management code across various places, making it difficult to maintain.

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MvcApp(
      child: Mvc(
        create: () => CounterController(),
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
            floatingActionButton: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IncrementCounterButton(),
                SizedBox(height: 8),
                DecrementCounterButton(),
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
```

`MvcStateScope` can manage all states stored in its scope and parent scopes. It is shared, and all child widgets can access it. It can also be obtained through dependency injection. Using it allows for sharing state across multiple widgets and updating state across components and services. This is both dangerous and powerful.

## Deleting State

When the widget containing the `MvcStateScope` is unmounted, all state instances within that scope are automatically deleted. Otherwise, you can only delete a specific type of state instance by calling the following method:

```dart
stateScope.deleteState<CounterState>();
```

Next: [`CSS Selectors`](selector.md)
