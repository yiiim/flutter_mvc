# Flutter Mvc

Flutter Mvc 是为了解决UI与逻辑分离的一个状态管理框架.

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
updateState<int>(updater: ((state) => state?.value++));
```

在更新状态时如果```MvcStateScope```曾获取过该状态，则```MvcStateScope```将会重建。如果在```MvcStateScope```区域中使用的多个状态，则任意状态发生更新这个```MvcStateScope```都会重建。

状态依靠泛型类型以及一个Object```key```来区分唯一性

## Controller

* Controller中保存了所有的状态，除了从```MvcStateScope```获取状态之外，Controller同样可以获取全部状态
* 在Controller中可以获取Model，Model同样是一个状态，也可以被```MvcStateScope```获取，在整个View被外部重建时Model状态将会更新
* 在Controller中可以获取当前Controller父级、同级、子级Controller
* 可以通过Mvc静态方法获取当前树中的任意Controller。方法原型如下，不传递context，则查找当前Element树中全部的Controller，如果传递context参数表示只查找context之前的Controller

```dart
T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where})
```

## MvcProxy

 可以使用```MvcProxyController```来作为一个只有逻辑没有UI的Controller，使用方式为：

```dart
MvcProxy(
  proxyCreate: () => Controller(),
  child: ...,
)
```

如果有很多个这样的Controller

```dart
MvcMultiProxy(
    proxyCreate: [
      () => Controller1(),
      () => Controller2(),
    ],
    child: ...,
  ),
),
```

即使没有UI，MvcProxyController同样是树中的一个节点

## View

MvcView的原型为

```dart
abstract class MvcView<TControllerType extends MvcController<TModelType>, TModelType> {
  Widget buildView(MvcContext<TControllerType, TModelType> ctx);
}
```

参数```MvcContext```中可以获取强类型的Controller和Model

## Model

model可以为任意类型

## MvcStateScope

```MvcStateScope```依靠```InheritedWidget```获取最近的指定类型的Controller，如果没有指定类型，则获取最近的```MvcController```

---

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
