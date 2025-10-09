# 依赖注入

## 依赖注入服务类型

**单例服务**： 通过`addSingleton`方法注入，在此作用域内以及子作用域内只会创建一个实例，所有请求该服务的地方都会得到同一个实例。

**瞬时服务**： 通过`addTransient`方法注入，每次请求都会创建一个新的实例。

**作用域服务**： 通过`addScoped`方法注入，每个作用域内都会创建一个实例，同一作用域内的请求会得到同一个实例，但不同作用域内的请求会得到不同的实例。

## 依赖注入作用域

`flutter_mvc` 使用依赖注入来管理对象以及 Widget。每一个 `MvcWidget` 都有一个依赖注入作用域，所以 Widget 树中的`MvcWidget`将形成一个依赖注入作用域树。每个作用域都可以注册自己的服务，并且可以访问父作用域中的服务。子作用域可以注册已经在父作用域中已经注册的服务，这样做的话子作用域中的服务会覆盖父作用域中的服务。如果父作用域注入的单例被子作用域覆盖，那么在子作用域中获取的该单例服务将会是子作用域中的实例，而不是父作用域中的实例。

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<SomeService>((_) => SomeService("Root"));
  },
  child: MvcApp(
    child: MvcDependencyProvider(
      provider: (collection) {
        collection.addSingleton<SomeService>((_) => SomeService("Child"));
      },
      child: MvcBuilder(
        builder: (context) {
          final someService = context.getMvcService<SomeService>();
          return Text(someService.name); // 输出 "Child"
        },
      ),
    ),
  ),
);
```

## 注入依赖的方式

### MvcDependencyProvider

`MvcDependencyProvider` 是一个 Widget，用于在其子树中提供依赖注入服务。你可以在这里注册各种服务（Service），这些服务可以是单例、瞬时或作用域服务。

```dart
MvcDependencyProvider(
  provider: (collection) {
    // 注册一个单例服务
    collection.addSingleton<ApiService>((_) => ApiService());
    // 注册一个瞬时服务
    collection.addTransient<TempService>((_) => TempService());
    // 注册一个作用域服务
    collection.addScoped<ScopedService>((_) => ScopedService());
  },
  child: MyApp(),
);
```

### MvcController

`MvcController` 也可以注册服务，通过重写 `initServices` 方法：

```dart
class MyController extends MvcController {
  @override
  void initServices(ServiceCollection collection) {
    super.initServices(collection);
    collection.addSingleton<SomeService>(SomeService());
  }
}
```

### MvcStatefulWidget

`MvcStatefulWidget` 也可以注册服务，通过重写 `initServices` 方法：

```dart
class MyStatefulWidget extends MvcStatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  MvcWidgetState<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends MvcWidgetState<MyStatefulWidget> {
  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
    collection.addSingleton<SomeService>(SomeService());
  }
}
```

## 获取依赖

### DependencyInjectionService

任何通过依赖注入注册的服务都可以通过`with DependencyInjectionService`然后通过`getService<T>()` 方法获取其他服务：

```dart
class MyService with DependencyInjectionService {
  void test() {
    final SomeService service = getService<SomeService>();
  }
}

MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<SomeService>((_) => SomeService());
    collection.addSingleton<MyService>((_) => MyService());
  },
  child: MvcApp(
    child: MvcBuilder(
        builder: (context) {
            MyService().test(); // crash
            context.getService<MyService>().test(); // ok
            return Container();
        },
    ),
  ),
);
```

当服务`with DependencyInjectionService`后，并且通过 getService 获取它之后，服务将会自动关联到一个作用域。对于作用域服务和瞬时服务，它们的作用域取决于获取它的作用域。对于单例服务，它的作用域总是位于注册它的作用域。`getService<T>()`方法会根据当前服务所关联的作用域来获取服务。

`MvcController` 和 `MvcView` 都已经混入了 `DependencyInjectionService`，所以你可以直接在它们中使用 `getService<T>()` 方法获取服务。

> `MvcController`是当前作用域中的单例服务，`MvcView`是当前作用域中的瞬时服务。

### 通过 Context 获取

你也可以通过 `BuildContext` 获取服务：

```dart
final SomeService service = context.getMvcService<SomeService>();
// or
final SomeService? service = context.tryGetMvcService<SomeService>();
```

context 会查找祖先树中最近的 `MvcWidget` 以获取服务，它获取服务的作用域就是这个 `MvcWidget` 所处的作用域。

获取服务时，千万要注意你所在的作用域。例如，你不应该在父作用域中获取子作用域中注册的服务，因为父作用域无法访问子作用域中的服务。

例如如下代码中，find1 会抛出异常，因为 SomeService 在子作用域中注册，父作用域无法访问它；而 find2 则可以正常获取到 SomeService 实例。

```dart
Builder(
  builder: (context) {
    // find 1 crash
    context.getMvcService<SomeService>();
    return MvcDependencyProvider(
      provider: (collection) {
        collection.addSingleton<SomeService>((_) => SomeService());
      },
      child: Builder(
        builder: (context) {
          // find 2 ok
          final someService = context.getMvcService<SomeService>();
          return Container();
        },
      ),
    );
  },
);
```

## 将服务与 Widget 关联

通过将你注入的服务`with MvcWidgetService`，你可以将服务与创建此服务的作用域的 Widget 关联起来。从而可以访问其 context，或者更新 Widget。并且获取的其`activate`和`deactivate`生命周期方法。

```dart
class MyService with MvcWidgetService {
  void test() {
    final size = context.size; // 使用 context
    update(); // 更新关联的 Widget
  }
· @override
  void mvcWidgetActivate() {}

  @override
  void mvcWidgetDeactivate() {}
}
```

这通常很危险，你需要清楚的了解你的服务所在的作用域，并且访问 context 时无法确保 context 仍然有效。幸运的是内存是安全的，当 Widget 销毁时服务也会被销毁。

更危险的是，如果你服务在初始化之前错过了`activate`和`deactivate`是没有补偿的。

如果你仅需要获取 context，建议使用`with DependencyInjectionService`，然后通过`getService<MvcContext>()`获取`MvcContext`, 这样获取的 `context` 和 `MvcWidgetService` 中的 `context` 是一样的。你通常不应该保存 `context` 的引用，除非你真的记得在 `dispose` 中清理它。
