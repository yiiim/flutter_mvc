# flutter_mvc

`flutter_mvc` is a Flutter state management framework focused on separating UI from business logic. It uses the MVC (Model-View-Controller) design pattern, combined with modern programming concepts like dependency injection and service location, to provide a clear, maintainable, and scalable application architecture.

[English](README.md) | [简体中文](README_CN.md)

## Features

- **Separation of Concerns**: Strictly divides `Model` (data), `View` (UI), and `Controller` (logic) to make code responsibilities clearer.
- **Dependency Injection**: A powerful built-in dependency injection system that integrates the Widget tree with dependency injection scopes, easily manages object lifecycles and dependencies, while allowing you to streamline Controllers by distributing logic into service objects.
- **Widget-to-Object Dependency**: You can make a Widget dependent on a specific type of object, triggering widget rebuilds when the object is updated.
- **Store State Management**: The framework provides a lightweight state management solution, supporting state management in `Controller`s and any dependency-injected object, and automatically updating the UI that depends on that state.
- **Context Access**: You can easily obtain the `BuildContext` from any dependency-injected object.
- **Precise Widget Targeting**: Similar to `querySelector` in web development, you can precisely target and update widgets by ID, Class, or even Widget type.
- **Easy to Learn**: The design is simple and intuitive, with easy-to-understand APIs, suitable for projects of any scale.

## Dependency Injection

`flutter_mvc` is built on the powerful dependency injection library [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection), which allows you to associate dependency-injected objects with widgets to unlock powerful features. For more details, please refer to the [Dependency Injection chapter](./doc/en/dependency_injection.md).

> `flutter_mvc` has an internal **dependency injection scope tree**, so you must use an `MvcApp` as the root widget to provide the root dependency injection container.

## Counter Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(
    MvcApp(
      child: Mvc(
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
    stateScope.createState(CounterState(0));
  }

  void increment() {
    stateScope.setState(
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
            appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: const Text('Flutter Demo Home Page')),
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

- [Dependency Injection](./doc/en/dependency_injection.md)
- [MVC Basics](./doc/en/mvc.md)
- [Store State Management](./doc/en/store.md)
- [CSS Selectors](./doc/en/selector.md)
- [Widget-to-Object Dependency](./doc/en/depend_on_service.md)

## Tutorials

- [Login Example](./doc/en/tutorials/login.md)
