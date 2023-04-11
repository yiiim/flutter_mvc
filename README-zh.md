# Flutter Mvc

语言: [English](https://github.com/yiiim/flutter_mvc) | 中文

Flutter Mvc 是一个包含了逻辑分离、状态管理、依赖注入的Flutter框架。 完整文档请[阅读此处](https://github.com/yiiim/flutter_mvc/wiki)

## Getting started

分别创建```Model，MvcView<TModelType,TControllerType>，MvcController<TModelType>```

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

然后使用```Mvc```

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

## 状态管理

首先在Controller的init方法中初始化状态

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0);
  }
}
```

在View中使用状态

```dart
Widget buildView(context) {
  return MvcStateScope<IndexPageController>(
    (state) {
      return Text("${state.get<int>()}");
    },
  );
}
```

在Controller中更新状态

```dart
updateState<int>(updater: ((state) => state.value++));
```

在更新状态时如果```MvcStateScope```曾获取过该状态，则```MvcStateScope```将会重建。如果在```MvcStateScope```的```builder```中使用了多个状态，则任意状态发生更新这个```MvcStateScope```都会重建。

## 依赖注入

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

```addController``` 添加```MvcController```，通过该方式添加过的Controller，在使用```Mvc```时可以不用提供```create```参数创建Controller，```Mvc```会从注入的依赖中创建Controller。

```addSingleton```添加单例，每次获取都为同一个实例

```addScopedSingleton```添加范围单例，在同一个范围内获取的是都一个实例，每个```MvcController```都是一个范围。

```add```每次获取都重新创建实例

```MvcDependencyProvider```对子级提供依赖，并且可以覆盖父级提供的依赖。

获取依赖：

在```MvcController```中使用```getService```方法：

```dart
getService<TestObject>();
```

## 完整样例

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
