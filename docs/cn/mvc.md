## MVC

### 使用 Mvc

```dart
void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: Mvc(
          create: () => IndexController(),
          model: IndexPageModel(),
        ),
      ),
    ),
  );
}
```

其中 Model 是可选的，如果您不需要通过外部传入数据，可以省略。

### Controller 示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class IndexPageModel {
  IndexPageModel();
  // **
}

class IndexController extends MvcController<IndexPageModel> {
  @override
  void init() {
    // 初始化代码
  }

  @override
  void didUpdateModel(TModelType oldModel) {
    // 当 Mvc Widget 被更新时调用
  }

  @override
  MvcView view() {
    return IndexPageView();
  }
}
```

Controller 继承自 `MvcController<TModelType>`，其中 `TModelType` 是传入的 Model 类型，如果没有传入 Model，可以使用 `MvcController<void>`。 `view()` 方法必须实现，返回一个 `MvcView` 实例。您可以通过 `update()` 方法来重建整个 `View`。或者通过[选择器](./selectors.md)或者[Store](./store.md)来局部更新。

### View 示例

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Center(
        child: Text(controller.title),
      ),
    );
  }
}
```

View 继承自 `MvcView<TControllerType>`，其中 `TControllerType` 是关联的 Controller 类型。必须实现 `buildView()` 方法，返回一个 Widget。您可以通过 `controller` 属性访问关联的 Controller 实例，通过 `context` 获取 `BuildContext`。

## Mvc和依赖注入
Controller 和 View 都是依赖注入对象，它们都可以可以通过 `getService<T>()` 方法获取其他依赖注入对象。


```dart
class IndexController extends MvcController<IndexPageModel> {
  @override
  void clickButton() {
    getService<SomeService>().doSomething();
  }
}
```

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    final someValue = getService<SomeService>().someValue;
    return Scaffold(
      body: Center(
        child: Text(someValue),
      ),
    );
  }
}
```