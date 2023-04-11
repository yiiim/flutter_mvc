
# 文档目录

* [Getting started](./#Getting-started)
  * [开始使用](./#开始使用)
  * [状态管理](./#状态管理)
  * [样例](./#样例)
* [Mvc](./Mvc/#Mvc)
  * [Model](./Mvc/#Model)
  * [View](./Mvc/#View)
  * [Controller](./Mvc/#Controller)
    * [创建Controller](./Mvc/#创建Controller)
    * [创建无View的Controller](./Mvc/#创建无View的Controller)
    * [Controller生命周期](./Mvc/#Controller生命周期)
    * [获取其他Controller](./Mvc/#获取其他Controller)
    * [MvcControllerPart](./Mvc/#MvcControllerPart)
* [状态管理](./Status/#状态管理)
  * [更新Widget](./Status/#更新Widget)
  * [初始化状态](./Status/#初始化状态)
  * [获取状态](./Status/#获取状态)
  * [更新状态](./Status/#更新状态)
  * [删除状态](./Status/#删除状态)
  * [StatePart](./Status/#StatePart)
  * [Model状态](./Status/#Model状态)
  * [状态总结](./Status/#状态总结)
* [依赖注入](./DependencyInjection/#依赖注入)
  * [注入依赖](./DependencyInjection/#注入依赖)
  * [获取依赖](./DependencyInjection/#获取依赖)
  * [服务范围](./DependencyInjection/#服务范围)
  * [MvcServiceScopedBuilder](./DependencyInjection/#MvcServiceScopedBuilder)

# Getting started

Flutter Mvc 是为了解决UI与逻辑分离的一个状态管理框架.

## 开始使用

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

在更新状态时如果```MvcStateScope```曾获取过该状态，则```MvcStateScope```将会重建。如果在```MvcStateScope```区域中使用的多个状态，则任意状态发生更新这个```MvcStateScope```都会重建。

## 样例

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
