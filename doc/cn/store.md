# 状态管理 (Store)

`flutter_mvc` 提供了一套轻量级、响应式的状态管理机制，其核心是 `MvcStateScope` 和 `context.stateAccessor`。这套机制允许你在控件树的任何部分创建、访问和监听状态，并在状态变化时自动重建相关的控件。

## 核心 API: `context.stateAccessor.useState`

这是 `flutter_mvc` 中最常用的状态管理 API。它集状态的创建、获取和监听于一体。

`useState<T>([T Function()? create])`

-   **泛型 `T`**: 你想要管理的状态对象的类型。
-   **`create` (可选)**: 一个函数，用于在状态首次被请求且不存在时创建它的实例。

### 工作机制

1.  **查找**: 当你调用 `context.stateAccessor.useState<MyState>()` 时，框架会从当前 `BuildContext` 开始，向上遍历控件树，查找最近的 `MvcStateScope` 中是否已存在 `MyState` 类型的实例。
2.  **创建**: 如果在任何父级 `MvcStateScope` 中都找不到 `MyState` 的实例，并且你提供了 `create` 函数，框架会调用该函数来创建一个新的状态实例，并将其存储在**当前**控件所在 `MvcStateScope` 中。
3.  **监听**: 调用 `useState` 的控件会自动注册为该状态的监听者。
4.  **返回**: 返回找到的或新创建的状态实例。

## 基本用法

### 1. 定义状态类

一个简单的 Dart 类 (POJO) 就可以作为状态。

```dart
class CounterState {
  int count = 0;
}
```

### 2. 创建和使用状态

在你的 `MvcWidget` 中，使用 `useState` 来获取并监听状态。

```dart
class CounterText extends MvcStatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 获取或创建 CounterState，并监听其变化
    final state = context.stateAccessor.useState<CounterState>(() => CounterState());

    return Text('Count: ${state.count}');
  }
}
```

-   `CounterText` 第一次构建时，`CounterState` 会被创建并初始化 `count` 为 0。
-   `CounterText` 会自动监听这个 `state` 对象的变化。

### 3. 更新状态

在任何可以访问 `BuildContext` 的地方（例如 `MvcController` 或另一个控件的事件回调中），你可以获取状态并修改它。

```dart
class MyController extends MvcController {
  void increment() {
    // 只获取状态，不监听
    final state = context.stateAccessor.getState<CounterState>();
    if (state != null) {
      // 直接修改状态对象的属性
      state.count++;
      // 通知框架状态已变更
      context.stateAccessor.setState(state);
    }
  }
}
```

**关键点**:
-   `context.stateAccessor.getState<T>()` 用于获取状态实例，但**不会**让当前控件监听它。
-   修改状态对象后，你**必须**调用 `context.stateAccessor.setState(state)` 来通知框架该状态已更新。
-   框架接收到通知后，会自动重建所有通过 `useState` 监听该状态的控件（例如上面的 `CounterText`）。

## 状态作用域 (`MvcStateScope`)

`MvcStateScope` 用于隔离状态。默认情况下，`MvcController` 会创建一个新的 `MvcStateScope`。这意味着在 `Mvc` 控件内部创建的状态默认只对该控件及其子控件可见。

你可以使用 `MvcStateScopeBuilder` 来手动创建新的状态作用域，这在需要将几个独立的控件共享一个临时状态时非常有用。

### 示例：共享状态

```dart
// main.dart
Mvc(
  controller: () => MyPageController(),
  view: (context, controller) {
    return Column(
      children: [
        // 这两个控件将共享同一个 CounterState 实例
        CounterText(),
        IncrementButton(),
      ],
    );
  }
)

// widgets.dart
class CounterText extends MvcStatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.stateAccessor.useState<CounterState>(() => CounterState());
    return Text('Count: ${state.count}');
  }
}

class IncrementButton extends MvcStatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final state = context.stateAccessor.getState<CounterState>();
        if (state != null) {
          state.count++;
          context.stateAccessor.setState(state);
        }
      },
      child: Text('Increment'),
    );
  }
}
```

在这个例子中，`CounterText` 和 `IncrementButton` 都在同一个 `MvcStateScope`（由 `MyPageController` 创建）下。`CounterText` 首次构建时创建了 `CounterState`。当 `IncrementButton` 被点击时，它获取到的是**同一个** `CounterState` 实例，更新它并触发 `CounterText` 重建。
