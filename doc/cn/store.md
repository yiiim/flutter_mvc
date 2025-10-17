# 状态存储 (Store)

`flutter_mvc` 提供了一套内置的、轻量级的状态管理方案，其核心是 `MvcRawStore`（通常简称为 Store）。Store 允许你在应用中创建、管理和响应状态变化，并能精确地更新依赖于该状态的 Widget。

## 核心概念

1.  **状态对象 (State Object)**:
    一个普通的 Dart 类，用于存放你的数据。例如 `class CounterState { int count; }`。

2.  **`MvcRawStore<T>`**:
    一个包装器，它持有你的状态对象 `T`，并混入了 `MvcDependableObject`，使其具备了依赖追踪和通知的能力。

3.  **`context.stateAccessor.useState<T, R>()`**:
    这是在 Widget 中**订阅**和**读取**状态的核心方法。它必须在 `build` 方法中调用。
    -   `T`: 你想要订阅的状态对象的类型。
    -   `R`: 你从状态对象 `T` 中实际**选择 (select)** 的数据部分。Widget 只会在这部分数据 `R` 发生变化时才重建。
    -   `initializer`: 一个可选的回调函数，用于在状态首次被访问且不存在时创建它。

4.  **`MvcStateScope`**:
    状态管理的作用域。它决定了状态的可见性和生命周期。默认情况下，整个应用共享一个根状态作用域。你可以创建新的 `MvcStateScope` 来隔离状态。

## 快速开始

下面是一个简单的计数器示例，展示了如何使用 Store 来管理状态。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

// 1. 定义你的状态类
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
                // 2. 在 build 方法中使用 useState 订阅状态
                //    - (CounterState state) => state.count 是一个 "selector" 函数
                //    - Widget 只在 state.count 变化时重建
                final count = context.stateAccessor.useState(
                  (CounterState state) => state.count,
                  // 首次访问时，如果 CounterState 不存在，则创建它
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
                  // 3. 获取当前作用域并更新状态
                  final scope = context.getMvcService<MvcStateScope>();
                  scope.setState<CounterState>((state) {
                    state.count++;
                  });
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

### 工作流程解析

1.  `Text` Widget 在 `build` 方法中调用 `context.stateAccessor.useState`，并提供了一个选择器 `(state) => state.count`。
2.  框架发现 `CounterState` 不存在，于是调用 `initializer` 创建了一个 `CounterState(0)` 的实例，并将其存储在当前的 `MvcStateScope` 中。
3.  `useState` 返回 `count` 的初始值 `0`，`Text` Widget 显示 "0"。同时，框架记录下此 Widget 依赖于 `CounterState` 的 `count` 属性。
4.  当按钮被点击时，`scope.setState<CounterState>` 被调用。
5.  框架找到 `CounterState` 的实例，执行 `(state) { state.count++; }`，`count` 变为 `1`。
6.  `setState` 完成后，框架通知所有依赖于 `CounterState` 的订阅者。
7.  框架检查到 `Text` Widget 的依赖项（`count` 属性）的值从 `0` 变成了 `1`。由于值发生了变化，框架触发该 `Text` Widget 的重建。
8.  `Text` Widget 重新 `build`，再次调用 `useState`，这次获取到新的 `count` 值 `1`，UI 更新为 "1"。

## 创建和更新状态

### 创建状态

-   **懒加载创建 (推荐)**: 如上例所示，通过 `useState` 的 `initializer` 参数。这是最常见和推荐的方式，状态只在首次需要时被创建。
-   **主动创建**: 你可以从依赖注入容器中获取 `MvcStateScope`，并调用 `createState` 方法。

    ```dart
    // 在 Controller 或 Service 中
    final scope = getService<MvcStateScope>();
    scope.createState(MyState("initial data"));
    ```

### 更新状态

-   通过 `MvcStateScope.setState<T>()` 或 `MvcController.stateScope.setState<T>()` 来更新。

    ```dart
    // 获取 MvcStateScope
    final scope = context.getMvcService<MvcStateScope>();
    
    // 更新状态
    scope.setState<MyState>((state) {
      state.value = "new value";
    });
    ```

## 状态作用域 (`MvcStateScope`)

默认情况下，所有状态都存在于根 `MvcStateScope` 中。这意味着在应用任何地方创建的 `CounterState` 都是同一个实例。

如果你需要隔离状态（例如，在一个列表中，每个列表项都有自己独立的计数器状态），你可以创建一个新的 `MvcStateScope`。

### 创建新作用域的方式

1.  **`MvcStateScopeBuilder` Widget**:
    这是一个专门用于创建新状态作用y域的 Widget。

    ```dart
    MvcStateScopeBuilder(
      builder: (context) {
        // 在这个子树中创建或访问的状态将位于一个新的、独立的作用域中
        return CounterWidget();
      },
    )
    ```

2.  **`Mvc` Widget**:
    默认情况下，每个 `Mvc` Widget 都会创建一个新的 `MvcStateScope`。你可以通过在 `MvcController` 中重写 `createStateScope` 属性来改变这个行为。

    ```dart
    class MyController extends MvcController {
      // 返回 false 来禁用自动创建新作用域
      @override
      bool get createStateScope => false;
    }
    ```

### 作用域查找规则

当获取一个状态时（如 `useState` 或 `getState`），框架会：
1.  在当前 `MvcStateScope` 中查找。
2.  如果找不到，则向上遍历 Widget 树，到父级的 `MvcStateScope` 中查找。
3.  重复此过程，直到找到状态或到达根作用域。

这种机制允许子 Widget 访问由父 Widget 提供的状态，同时也允许子 Widget 通过创建新作用域来“覆盖”或“隐藏”父级的同类型状态。
