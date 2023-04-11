# Flutter Mvc

语言: English | [中文](https://github.com/yiiim/flutter_mvc/blob/master/README-zh.md)

Flutter Mvc is a Flutter framework that includes logic separation, state management, and dependency injection. For full documentation, please [read here](https://github.com/yiiim/flutter_mvc/wiki).

## Getting started

Create `Model`, `MvcView<TModelType, TControllerType>`, and `MvcController<TModelType>` separately.

```dart
/// Model
class IndexPageModel {
  IndexPageModel({required this.title});
  final String title;
}
/// Controller
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  MvcView view(IndexPageModel model) {
    return IndexPage();
  }
}
/// View
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(context) {
    //...
  }
}
```

Then use `Mvc`.

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Mvc<IndexPageController, IndexPageModel>(
        create: () => IndexPageController(),
        model: IndexPageModel(title: "Flutter Mvc Demo"),
      ),
    );
  }
}
```

## State management

First initialize the state in the Controller's `init` method.

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0);
  }
}
```

Use the state in the View.

```dart
Widget buildView(context) {
  return MvcStateScope<IndexPageController>(
    (state) {
      return Text("${state.get<int>()}");
    },
  );
}
```

Update the state in the Controller.

```dart
updateState<int>(updater: ((state) => state?.value++));
```

When updating the state, if `MvcStateScope` has ever accessed the state, `MvcStateScope` will be rebuilt. If multiple states are used in the `builder` of `MvcStateScope`, this `MvcStateScope` will be rebuilt whenever any state is updated.

## Dependency injection

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addController<IndexPageController>((serviceProvider) => IndexPageController());
    collection.addSingleton<TestSingletonObject>((serviceProvider) => TestSingletonObject());
    collection.addScopedSingleton<TestScopedSingletonObject>((serviceProvider) => TestScopedSingletonObject());
    collection.add<TestObject>((serviceProvider) => TestObject());
  },
  child: ...,
);
```

`addController` adds an `MvcController`. Controllers added in this way can be created without providing a `create` parameter when using `Mvc`. `Mvc` will create the controller from the injected dependencies.

`addSingleton` adds a singleton object, which always returns the same instance when retrieved.

`addScopedSingleton` adds a scoped singleton object, which returns the same instance within the same scope. Each `MvcController` is a scope.

`add` creates a new instance every time it is retrieved.

`MvcDependencyProvider` provides dependencies for child widgets and can override dependencies provided by parent widgets.

Get dependencies:

Use the `getService` method in `MvcController`:

```dart
getService<TestObject>();
```

## Full example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Mvc<IndexPageController, IndexPageModel>(
        create: () => IndexPageController(),
        model: IndexPageModel(title: "Flutter Demo"),
      ),
    );
  }
}

/// Model
class IndexPageModel {
  IndexPageModel({required this.title});
  final String title;
}

/// View
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ctx.model.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            MvcStateScope<IndexPageController>(
              (state) {
                return Text("${state.get<int>()}");
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctx.controller.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Controller
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0); // 初始化状态
  }

  void incrementCounter() {
    updateState<int>(updater: ((state) => state?.value++)); // 更新状态
  }

  @override
  MvcView view(model) {
    return IndexPage();
  }
}
```
