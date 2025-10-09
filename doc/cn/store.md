# 状态商店

`flutter_mvc` 提供了一个简单的状态管理解决方案，称为 Store。Store 是一个可以存储状态的对象，并且它还可以关联 `BuildContext`，以便在状态变化时通知相关的 Widget 进行重建。

## 快速开始

下面是一个简单的计数器示例，展示了如何使用 Store 来管理状态。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

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
                final count = context.stateAccessor.useState(
                  (CounterState state) => state.count,
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
                  final MvcWidgetScope widgetScope = context.getMvcService<MvcWidgetScope>();
                  widgetScope.setState<CounterState>(
                    (state) {
                      state.count++;
                    },
                  );
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

当按下浮动按钮时，会触发`CounterState`更新，并且关联的 Widget 会有条件的更新，比如上面的`Text` Widget 只获取了`count`字段，所以只有当`count`字段变化时它才会更新。

## context.stateAccessor

`context.stateAccessor` 是`flutter_mvc`推荐使用 Store 的唯一方式，你只能在构建期间使用它，`useState<T, R>`是一个泛型方法，接受一个 `R Function(T)`参数，通常，你无需指定全部的泛型类型，只需要在`R Function(T)`中指定`T`状态的类型即可，返回 R 类型编译器会自动推断出来。当状态更新时，只有当`R`类型的值变化时，才会触发 Widget 重建。所以如果`R`是一个对象，如果你只修改了对象的某个字段，而没有修改对象本身，那么 Widget 不会重建。

`useState` 还有一个可选的 `initializer` 参数，用于初始化状态对象，当状态对象不存在时会调用它来创建一个新的状态对象，否则会抛出异常。

## 创建和更新状态

除了使用`context.stateAccessor.useState`中的`initializer`参数来创建状态对象，你还可以通过`MvcWidgetScope`的`createState<T>(T state)`方法来创建状态对象，`MvcWidgetScope`是一个在 `MvcApp` 中注册的作用域服务，你可以通过依赖注入获取它：

```dart
class MyService with DependencyInjectionService {
  late final MvcWidgetScope widgetScope = getService<MvcWidgetScope>();
  void incrementCounter() {
    widgetScope.setState<CounterState>((state) {
      state.count++;
    });
  }

  @override
  FutureOr<dynamic> dependencyInjectionServiceInitialize() {
    widgetScope.createState(CounterState(0));
  }
}
```

`MyService` 是一个依赖注入对象，你可以在它的初始化方法中创建状态。使用`MyService`修改 计数器示例。

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<MyService>(
      (_) => MyService(),
      initializeWhenServiceProviderBuilt: true,
    );
  },
  child: Scaffold(
    body: Center(
      child: Builder(
        builder: (context) {
          final count = context.stateAccessor.useState(
            (CounterState state) => state.count
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
            context.getMvcService<MyService>().incrementCounter();
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
);
```

`initializeWhenServiceProviderBuilt` 参数确保在服务提供者构建完成后立即初始化服务，否则服务会等到第一次获取它时才会初始化。

需要注意的是，你不能创建重复类型的状态对象，否则会抛出异常，即使在不同的作用域中也不行。状态具有单独的作用域范围，你可以通过`MvcStateScope`Widget 来创建一个新的状态作用域，在新的作用域中可以创建重复类型的状态对象覆盖父作用域中的状态对象。覆盖后的状态对象只在当前作用域及其子作用域中可见。每一个 `Mvc` Widget 也会创建一个独立的状态作用域， 你可以通过重写`MvcController`的`createStateScope`属性来禁止此行为。

> 得益于状态独立作用域，即使在子Widget作用域中创建的状态，只要位于同一个状态作用域，父Widget作用域也可以访问它。
