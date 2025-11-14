# 状态管理 (Store)

`flutter_mvc` 提供了一套轻量级、响应式的状态管理机制，其核心是 `MvcStateScope` 和 `context.stateAccessor`。这套机制允许你在控件树的任何部分创建、访问和监听状态，并在状态变化时自动重建相关的控件。

## 核心 API: `context.stateAccessor.useState`

这是 `flutter_mvc` 中最常用的状态管理 API。它集状态的创建、获取和监听于一体。

`R useState<T extends Object, R>(R Function(T use) fn, {T Function()? initializer, MvcRawStore<T> Function(T state)? storeInitializer})`

- **泛型 `T`**: 你想要管理的状态对象的类型。
- **泛型 `R`**: 你要从状态中提取并监听的值的类型。
- **`R Function(T use) fn`**: 从状态对象中提取你想监听的值的函数。
- **`initializer` (可选)**: 一个函数，用于在状态首次被请求且不存在时创建它的实例。
- **`storeInitializer` (可选)**: 一个函数，用于自定义状态存储类的初始化逻辑。

**示例**:

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final (int count, String text) = context.stateAccessor.useState(
      (CounterState state) => (state.count, state.text),
      initializer: () => CounterState(0, ""),
    );
    return Text("MyWidget: count=$count, text=$text");
  }
}
```

这会在从 context 所在的状态作用域查找 `CounterState` 实例，如果不存在则调用 `initializer` 创建一个新的状态。然后，它会提取并监听 `count` 和 `text` 字段。当这两个字段中的任何一个发生变化时，调用 `useState` 的控件将自动重建。

> 你不必提供泛型参数，Dart 编译器通常可以根据传入的函数自动推断出 `T` 和 `R` 的类型。

### 工作机制

1.  **查找**: 当你调用 `context.stateAccessor.useState<MyState, R>()` 时，框架会从当前 `BuildContext` 开始查找最近的 `MvcStateScope` 中是否已存在 `MyState` 类型的状态。
2.  **创建**: 如果在任何父级 `MvcStateScope` 中都找不到 `MyState` 的实例，并且你提供了 `initializer` 函数，框架会调用该函数来创建一个新的状态实例，并将其存储在**当前**控件所在 `MvcStateScope` 中。
3.  **监听**: 调用 `useState` 的控件会自动注册为该状态的监听者,并且只监听通过 `fn` 提取的字段。当这些字段发生变化时，控件会被标记为需要重建。
4.  **返回**: 返回找到的或新创建的状态实例。

## 核心类： `MvcStateScope`

`MvcStateScope`表示一个状态作用域，可以在 Widget 树中的不同位置创建独立的状态作用域，状态作用域的所有子级 Widget 都可以使用作用域中的状态。状态相关的操作都是在这个类上进行的。包括创建状态、获取状态、更新状态和删除状态。

```dart
abstract class MvcStateScope {
  /// Creates and registers a new state of type [T].
  /// Throws an error if a state of the same type already exists in the current scope.
  MvcSetState<T> createState<T extends Object>(T state);

  /// Updates a state of type [T].
  /// The [set] function receives the current state and can modify it.
  void setState<T extends Object>([void Function(T state)? set]);

  /// Gets the current state of type [T].
  /// Returns `null` if the state does not exist.
  T? getState<T extends Object>();

  /// Gets the raw store for a state of type [T].
  /// Returns `null` if the store does not exist.
  MvcRawStore<T>? getStore<T extends Object>();

  /// A more specific version of [getStore] that allows specifying the exact store type.
  R? getStoreOfExactType<T extends Object, R extends MvcRawStore<T>>();

  /// Deletes a state of type [T] from the current scope.
  void deleteState<T extends Object>();

  /// Listens to changes in a state of type [T] and returns a value of type [R].
  ///
  /// The [listener] is called whenever the selected part of the state changes.
  /// The [use] function selects the part of the state to listen to.
  R listenState<T extends Object, R>(MvcStateListener listener, [R Function(T state)? use]);

  /// Removes a state listener.
  void removeStateListener<T extends Object>(MvcStateListener listener);
}
```

在`MvcWidgetState`、`MvcController`或者`BuildContext`中都可以通过 `stateScope` 属性获取到与当前控件最近的 `MvcStateScope`，或者通过依赖注入使用`MvcStateScope`类型来获取，通过依赖注入获取时要注意作用域规则，确保你获取的是正确作用域中的实例。依赖注入作用域规则请参考[依赖注入章节](./dependency_injection.md#依赖注入作用域)。

更多具体内容参考[状态作用域章节](./scope.md#mvcstatescope)。

## 基本用法

一个简单的 Dart 类就可以作为状态。

```dart
class CounterState {
  int count = 0;
}
```

### `createStateIfAbsent` 和 `MvcSetState`

```dart
void main() {
  runApp(
    const MvcApp(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final setState = context.stateScope.createStateIfAbsent<CounterState>(
      () => CounterState(0),
    );
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              final count = context.stateAccessor.useState((CounterState state) => state.count);
              return Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState((state) => state.count++),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

`createStateIfAbsent` 方法会在状态不存在时创建它，并返回一个 `MvcSetState` 方法，对象可以用来更新状态。这种方式适合在 StatelessWidget 中使用。

### `MvcStatefulService`

```dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MvcApp(
      child: MvcDependencyProvider(
        child: const MyWidget(),
        provider: (collection) {
          collection.addSingleton(
            (_) => MyStatefulService(),
            initializeWhenServiceProviderBuilt: true,
          );
        },
      ),
    );
  }
}

class MyStatefulService with DependencyInjectionService, MvcStatefulService<CounterState> {
  void increment() {
    setState((state) {
      state.count++;
    });
  }

  @override
  CounterState initializeState() {
    return CounterState(0);
  }
}

class MyWidget extends MvcStatelessWidget {
  const MyWidget({super.key, super.id, super.classes, super.attributes});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              final count = context.stateAccessor.useState((CounterState state) => state.count);
              return Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium,
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.getService<MyStatefulService>().increment(),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

`MvcStatefulService` 是一种将状态与依赖注入结合使用的方式。它允许你在服务中创建和管理状态，并通过依赖注入在任何需要的地方访问和修改该状态。

> `initializeWhenServiceProviderBuilt` 参数确保在Widget构建时，创建并初始化服务（创建状态）。

> `MvcController` 也可以混入 `MvcStatefulService` 来管理状态。

> 这是最为推荐的方式。

### MvcStateScope

你可以直接使用`MvcStateScope`来管理状态，不过我们通常不建议这么做，因为这样会让状态管理代码分散在各个地方，难以维护。

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MvcApp(
      child: Mvc(
        create: () => CounterController(),
      ),
    );
  }
}

class CounterController extends MvcController<void> with MvcStatefulService<CounterState> {
  @override
  MvcView view() {
    return CounterView();
  }

  @override
  CounterState initializeState() {
    return CounterState(0);
  }
}

class IncrementCounterButton extends StatelessWidget {
  const IncrementCounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final stateScope = context.stateScope;
        stateScope.setState(
          (CounterState state) {
            state.count++;
          },
        );
      },
      child: const Text('Increment Counter'),
    );
  }
}

class DecrementCounterButton extends StatelessWidget {
  const DecrementCounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final stateScope = context.stateScope;
        stateScope.setState(
          (CounterState state) {
            state.count--;
          },
        );
      },
      child: const Text('Decrement Counter'),
    );
  }
}

class CounterView extends MvcView<CounterController> {
  @override
  Widget buildView() {
    return Builder(
      builder: (context) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  final count = context.stateAccessor.useState((CounterState state) => state.count);
                  return Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            floatingActionButton: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IncrementCounterButton(),
                SizedBox(height: 8),
                DecrementCounterButton(),
              ],
            ),
          ),
        );
      },
    );
  }
}
```
`MvcStateScope`可以管理储存在该作用域以及父级作用域内的所有状态，它是共享的，所有子级控件都可以访问到它，并且还可以通过依赖注入方式获取。使用它可以实现跨多个 Widget 共享状态，跨组件、跨服务更新状态。这很危险，也很强大。

## 删除状态

在`MvcStateScope`所在的 Widget 卸载时，会自动删除该作用域内的所有状态实例。否则只能通过调用以下方法来删除特定类型的状态实例。

```dart
stateScope.deleteState<CounterState>();
```

下一篇：[`Css 选择器`](selector.md)