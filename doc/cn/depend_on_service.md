# 依赖于对象 (`MvcDependableObject`)

除了使用 `MvcController` 和 `MvcRawStore` 进行状态管理外，`flutter_mvc` 还提供了一种更轻量、更灵活的方式来让 Widget 响应变化：依赖于一个普通的可观察对象。

你可以让任何对象变得“可依赖”，只要它混入 (`mixin`) `MvcDependableObject`。当这个对象的状态发生变化时，它可以通知所有依赖于它的 Widget 进行重建。

这对于创建需要在多个不直接相关的 Widget 之间共享和同步的、可复用的业务逻辑或状态非常有用。

## 核心概念

1.  **`MvcDependableObject`**:
    一个 `mixin`，为你的类增加了依赖追踪和通知的能力。
    -   `notifyAllDependents()`: 通知所有依赖于此对象的 Widget 进行重建。

2.  **`context.dependOnMvcService<T>()`**:
    这是一个 `BuildContext` 的扩展方法。当你在 Widget 的 `build` 方法中调用它时，它会做两件事：
    -   从依赖注入容器中获取类型为 `T` 的服务实例。
    -   将当前 Widget 注册为此服务实例的一个“依赖者”。

当服务实例调用 `notifyAllDependents()` 时，所有注册的依赖者（即那些调用了 `dependOnMvcService` 的 Widget）都会被标记为“需要重建”，从而实现 UI 的自动更新。

## 快速开始

下面是一个简单的计数器示例，展示了如何使用 `MvcDependableObject` 来更新 Widget。

```dart
// 1. 创建一个混入 MvcDependableObject 的服务类
class CounterService with MvcDependableObject {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    // 3. 当状态改变时，通知所有依赖者
    notifyAllDependents();
  }
}

void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: MvcDependencyProvider(
          provider: (collection) {
            // 注意：为了让多个 Widget 共享同一个实例，这里必须注入为单例
            collection.addSingleton<CounterService>((_) => CounterService());
          },
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  // 2. 在 build 方法中调用 dependOnMvcService 建立依赖关系
                  final counterService = context.dependOnMvcService<CounterService>();
                  return Text(
                    '${counterService.count}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton(
                  onPressed: () {
                    // 获取服务实例并调用方法
                    context.getMvcService<CounterService>().increment();
                  },
                  tooltip: 'Increment',
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
```

### 注意事项

-   **注入为单例**: 为了确保应用的不同部分访问的是同一个 `CounterService` 实例，你应该将其注册为单例 (`addSingleton`)。如果注册为瞬时 (`add`) 或作用域 (`addScoped`)，那么每次获取的可能是不同实例，`notifyAllDependents()` 将无法正确通知到所有预期的 Widget。

## 高级用法：精细化更新

`MvcDependableObject` 还支持更复杂的场景，例如，只更新特定的依赖者。这可以通过 `aspect` 参数实现。

-   **`aspect`**: 允许你根据变化的不同“方面”来决定是否更新一个 Widget。

这在处理复杂对象时非常有用，可以避免不必要的重建，从而优化性能。你可以在 `MvcDependableObject` 的实现中重写 `shouldNotifyDependents` 方法来控制更新逻辑。
