# MVC 核心组件

`flutter_mvc` 框架的核心是 `Mvc` Widget，它将模型（Model）、视图（View）和控制器（Controller）有机地结合在一起。

## 1. `Mvc` Widget

`Mvc` Widget 是连接 Controller 和 View 的桥梁。它负责创建和管理 Controller 的生命周期，并根据 Controller 的指令来构建和更新 View。

**基本用法:**

```dart
void main() {
  runApp(
    MaterialApp(
      home: MvcApp( // MvcApp 是所有 flutter_mvc 应用的根
        child: Mvc(
          create: () => IndexController(), // 提供 Controller 的创建工厂
        ),
      ),
    ),
  );
}
```

- `create`: 一个返回 `MvcController` 实例的函数。这是必须的，除非你通过基于[依赖注入](./dependency_injection.md)的`addController`方法在父级作用域中提供了 Controller。

## 2. Controller (控制器)

Controller 是业务逻辑的核心。它处理用户输入、管理状态、与数据模型交互，并决定何时更新 View。

**Controller 示例:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class IndexController extends MvcController {
  // 重写 view 方法，返回一个 MvcView 实例
  @override
  MvcView<IndexController> view() => IndexPageView();

  int _counter = 0;
  int get counter => _counter;

  // 业务逻辑方法
  void increment() {
    _counter++;
    // 通知 View 重建
    update();
  }

  // --- 生命周期方法 ---

  @override
  void init() {
    super.init();
    // 在 Controller 初始化时调用，适合执行一次性设置
  }

  @override
  void didUpdateModel(TModelType oldModel) {
    super.didUpdateModel(oldModel);
    // 在模型更新时调用，适合处理模型变化
  }
}
```

- **`view()`**: 必须实现此方法，返回一个 `MvcView` 实例。
- **`update()`**: 调用此方法会触发 `MvcView` 的 `buildView` 方法，从而重建整个 View。对于更精细的控制，可以使用[选择器](./selector.md)或[Store](./store.md)进行局部更新。

## 3. View (视图)

View 负责 UI 的呈现。它是一个纯粹的 UI 层，只负责根据 Controller 提供的状态来构建 Widget。

**View 示例:**

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        // 通过 controller 访问模型数据
        title: Text("MVC Demo"),
      ),
      body: Center(
        child: Text(
          '${controller.counter}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // 调用 controller 的方法来处理用户交互
        onPressed: () => controller.increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- **泛型**: `MvcView<TControllerType>` 中的 `TControllerType` 是其关联的 Controller 类型。
- **`buildView()`**: 必须实现此方法，返回一个 Widget。这是构建视图 UI 的地方。
- **`controller`**: 通过 `controller` 属性可以安全地访问关联的 Controller 实例，从而获取数据或调用其方法。
- **`context`**: 可以通过 `context` 属性获取 `BuildContext`。

## `Mvc` 与依赖注入

`MvcController` 和 `MvcView` 都被集成到了依赖注入系统中。

- `MvcController` 在其作用域内被注册为**单例**。
- `MvcView` 在其作用域内被注册为**瞬时**的。

这意味着你可以在 Controller 和 View 内部，使用 `getService<T>()` 来获取任何其他已注册的服务，从而实现清晰的关注点分离。

**示例：在 Controller 中使用服务**

```dart
class IndexController extends MvcController {
  void performAction() {
    // 假设 AuthService 已经被注册
    final authService = getService<AuthService>();
    authService.login();
  }

  @override
  MvcView<IndexController> view() => IndexPageView();
}
```

**示例：在 View 中使用服务**

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    // 假设 SettingsService 已经被注册
    final settings = getService<SettingsService>();

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.black : Colors.white,
      // ...
    );
  }
}
```

下一篇：[`Store 状态管理`](store.md)