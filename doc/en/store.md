# State Store

`flutter_mvc` provides a simple state management solution called Store. Store is an object that can store state, and it can also be associated with `BuildContext` to notify related widgets to rebuild when state changes.

## Quick Start

Here's a simple counter example that shows how to use Store to manage state.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class CounterState {
  CounterState(this.count);
  int count;
}

void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                final count = context.stateAccessor.useState(
                  (CounterState state) => state.count,
                  initializer: () => CounterState(0),
                );
                return Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
          ),
          floatingActionButton: Builder(
            builder: (context) {
              return FloatingActionButton(
                onPressed: () {
                  final MvcWidgetScope widgetScope = context.getMvcService<MvcWidgetScope>();
                  widgetScope.setState<CounterState>(
                    (state) {
                      state.count++;
                    },
                  );
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
```

When the floating button is pressed, it triggers a `CounterState` update, and the associated Widget will update conditionally. For example, the `Text` Widget above only gets the `count` field, so it will only update when the `count` field changes.

## context.stateAccessor

`context.stateAccessor` is the only recommended way to use Store in `flutter_mvc`. You can only use it during the build phase. `useState<T, R>` is a generic method that accepts an `R Function(T)` parameter. Usually, you don't need to specify all generic types, just specify the `T` state type in `R Function(T)`, and the compiler will automatically infer the return `R` type. When the state is updated, the Widget will only rebuild when the value of type `R` changes. So if `R` is an object, if you only modify a field of the object without modifying the object itself, the Widget will not rebuild.

`useState` also has an optional `initializer` parameter for initializing the state object. It will be called to create a new state object when the state object doesn't exist, otherwise an exception will be thrown.

## Creating and Updating State

In addition to using the `initializer` parameter in `context.stateAccessor.useState` to create state objects, you can also create state objects through the `createState<T>(T state)` method of `MvcWidgetScope`. `MvcWidgetScope` is a scoped service registered in `MvcApp`, and you can get it through dependency injection:

```dart
class MyService with DependencyInjectionService {
  late final MvcWidgetScope widgetScope = getService<MvcWidgetScope>();
  void incrementCounter() {
    widgetScope.setState<CounterState>((state) {
      state.count++;
    });
  }

  @override
  FutureOr<dynamic> dependencyInjectionServiceInitialize() {
    widgetScope.createState(CounterState(0));
  }
}
```

`MyService` is a dependency injection object, and you can create state in its initialization method. Using `MyService` to modify the counter example:

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<MyService>(
      (_) => MyService(),
      initializeWhenServiceProviderBuilt: true,
    );
  },
  child: Scaffold(
    body: Center(
      child: Builder(
        builder: (context) {
          final count = context.stateAccessor.useState(
            (CounterState state) => state.count
          );
          return Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium,
          );
        },
      ),
    ),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<MyService>().incrementCounter();
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
);
```

The `initializeWhenServiceProviderBuilt` parameter ensures that the service is initialized immediately after the service provider is built, otherwise the service will wait until it's first accessed.

Note that you cannot create duplicate types of state objects, otherwise an exception will be thrown, even in different scopes. State has separate scope ranges, and you can create a new state scope through the `MvcStateScope` Widget. In the new scope, you can create duplicate types of state objects to override state objects in the parent scope. The overridden state objects are only visible in the current scope and its child scopes. Each `Mvc` Widget also creates an independent state scope, and you can disable this behavior by overriding the `createStateScope` property of `MvcController`.

> Thanks to the independent state scope, even state created in child widget scopes can be accessed by parent widget scopes as long as they are in the same state scope.