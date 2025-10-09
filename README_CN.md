# flutter_mvc

`flutter_mvc` 是一个专注于 UI 与业务逻辑分离的 Flutter 状态管理框架。它使用 MVC（Model-View-Controller）设计模式，并结合了依赖注入和服务定位等现代编程理念，旨在提供一种结构清晰、易于维护和扩展的应用架构。

[English](README.md) | 简体中文

## 特性

- **关注点分离 (Separation of Concerns)**: 严格划分 `Model` (数据)、`View` (视图) 和 `Controller` (逻辑)，使代码职责更清晰。
- **依赖注入**: 内置强大的依赖注入系统，轻松管理对象的生命周期和依赖关系。
- **Widget 依赖于对象**: 通过依赖注入，您可以将单个 Widget 依赖于特定类型的对象，通过对象更新来触发 Widget 的重建。
- **Store 状态管理**: 框架提供了一种轻量级的状态管理方式，支持在 `Controller` 和任意依赖注入对象中管理状态，并自动更新依赖该状态的 UI。
- **生命周期管理**: 为 `Controller` 甚至是依赖注入的任意对象提供了清晰的生命周期方法。
- **context 访问**: 您可以轻松的为任意依赖注入对象获取 `BuildContext`。
- **Widget 精确定位**: 类似 Web 中的 `querySelector`，通过 ID 、Class 甚至是 Widget 类型来精确定位/更新 Widget。

## 依赖注入

`flutter_mvc` 基于强大的依赖注入库[dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)，它允许你将依赖注入对象与 Widget 关联以获取强大的功能。详细内容请参考[依赖注入章节](./docs/cn/dependency_injection.md)。

> `flutter_mvc` 内部有一个**依赖注入范围树**，所以必须使用一个 MvcApp 作为根 Widget 以便提供根依赖注入容器。

## Counter 示例

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

## 文档目录

- [依赖注入](./doc/cn/dependency_injection.md)
- [MVC 基础](./doc/cn/mvc.md)
- [Store 状态管理](./doc/cn/store.md)
- [Css 选择器](./doc/cn/selector.md)
- [Widget 依赖于对象](./doc/cn/depend_on_service.md)
