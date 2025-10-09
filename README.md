# flutter_mvc

`flutter_mvc` is a Flutter state management framework focused on separating UI from business logic. It uses the MVC (Model-View-Controller) design pattern and incorporates modern programming concepts such as dependency injection and service location, aiming to provide a clear, maintainable, and scalable application architecture.

English | [简体中文](README_CN.md)

## Features

- **Separation of Concerns**: Strictly separates `Model` (data), `View` (presentation), and `Controller` (logic) to make code responsibilities clearer.
- **Dependency Injection**: Built-in powerful dependency injection system that easily manages object lifecycles and dependency relationships.
- **Widget Depends on Objects**: Through dependency injection, you can make individual widgets depend on specific types of objects, triggering widget rebuilds through object updates.
- **Store State Management**: The framework provides a lightweight state management approach, supporting state management in `Controller` and any dependency-injected objects, with automatic UI updates for dependent states.
- **Lifecycle Management**: Provides clear lifecycle methods for `Controller` and even any dependency-injected objects.
- **Context Access**: You can easily obtain `BuildContext` for any dependency-injected object.
- **Precise Widget Targeting**: Similar to `querySelector` in Web, precisely target/update widgets through ID, Class, or even widget types.

## Dependency Injection

`flutter_mvc` is based on the powerful dependency injection library [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection), which allows you to associate dependency-injected objects with widgets to gain powerful functionality. For detailed information, please refer to the [Dependency Injection section](./docs/en/dependency_injection.md).

> `flutter_mvc` has an internal **dependency injection scope tree**, so you must use an MvcApp as the root widget to provide the root dependency injection container.

## Counter Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(
    MvcApp(
      child: Mvc<CounterController, void>(
        create: () => CounterController(),
      ),
    ),
  );
}

class CounterState {
  CounterState(this.count);
  int count;
}

class CounterController extends MvcController<void> {
  @override
  void init() {
    widgetScope.createState(CounterState(0));
  }

  void increment() {
    widgetScope.setState(
      (CounterState state) {
        state.count++;
      },
    );
  }

  @override
  MvcView view() {
    return CounterView();
  }
}

class CounterView extends MvcView<CounterController> {
  @override
  Widget buildView() {
    return Builder(
      builder: (context) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text('Flutter Demo Home Page')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('You have pushed the button this many times:'),
                  Builder(
                    builder: (context) {
                      final count = context.stateAccessor.useState((CounterState state) => state.count);
                      return Text(
                        '$count',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: controller.increment,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
```

## Documentation

- [Dependency Injection](./docs/en/dependency_injection.md)
- [MVC Basics](./docs/en/mvc.md)
- [Store State Management](./docs/en/store.md)
- [CSS Selector](./docs/en/selector.md)
- [Widget Depends on Service](./docs/en/depend_on_service.md)
