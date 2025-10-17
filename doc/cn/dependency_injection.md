# 依赖注入

`flutter_mvc` 内置了一个功能强大的依赖注入（Dependency Injection, DI）系统，它基于 `dart_dependency_injection` 包，并与 Flutter 的 Widget 生命周期深度集成。DI 是管理应用中对象（服务）的创建和生命周期的核心机制。

## 依赖注入服务类型

你可以将服务注册为以下三种生命周期类型：

**1. 单例 (Singleton)**
通过 `addSingleton` 方法注册。在注册此服务的**作用域及其所有子作用域**内，只会创建一个实例。所有对该服务的请求都会返回同一个实例。

**2. 瞬时 (Transient)**
通过 `addTransient` 或 `add` 方法注册。**每次请求**都会创建一个新的实例。

**3. 作用域 (Scoped)**
通过 `addScoped` 方法注册。在**同一个作用域内**的多次请求会返回同一个实例，但**不同作用域**的请求会返回不同的实例。

## 依赖注入作用域

`flutter_mvc` 将 Widget 树与依赖注入作用域树紧密结合。

-   每个 `MvcWidget`（包括 `Mvc`, `MvcStatelessWidget`, `MvcStatefulWidget`）都会创建一个新的依赖注入作用域。
-   这形成了一个与 Widget 树平行的**作用域树**。
-   子作用域可以访问父作用域中注册的服务。
-   如果在子作用域中注册了与父作用域中**相同类型**的服务，子作用域中的服务会**覆盖**（或称“遮蔽”）父作用域中的服务。当在该子作用域或其后代中请求该服务时，将获取到子作用域中注册的实例。

**示例：作用域覆盖**
```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<SomeService>((_) => SomeService("Root"));
  },
  child: MvcDependencyProvider( // 创建了一个子作用域
    provider: (collection) {
      // 在子作用域中覆盖了 SomeService
      collection.addSingleton<SomeService>((_) => SomeService("Child"));
    },
    child: Builder(
      builder: (context) {
        // 获取 SomeService，将得到子作用域中的 "Child" 实例
        final someService = context.getMvcService<SomeService>();
        return Text(someService.name); // 屏幕上显示 "Child"
      },
    ),
  ),
);
```

## 注入依赖的方式

有多种方式可以在作用域中注册服务：

### 1. `MvcDependencyProvider`

这是一个专门用于提供依赖的 Widget。它会在其子树中创建一个新的作用域，并通过 `provider` 回调注册服务。

```dart
MvcDependencyProvider(
  provider: (collection) {
    // 注册一个单例服务
    collection.addSingleton<ApiService>((_) => ApiService());
    // 注册一个瞬时服务
    collection.add<TempService>((_) => TempService());
    // 注册一个作用域服务
    collection.addScoped<ScopedService>((_) => ScopedService());
  },
  child: MyApp(),
);
```

### 2. `MvcController`

在 `MvcController` 中，可以重写 `initServices` 方法来注册服务。这些服务在该 Controller 关联的 `Mvc` Widget 的作用域内可用。

```dart
class MyController extends MvcController {
  @override
  void initServices(ServiceCollection collection) {
    super.initServices(collection);
    collection.addSingleton<SomeService>((_) => SomeService());
  }
}
```

### 3. `MvcStatefulWidget`

在其对应的 `MvcWidgetState` 中，同样可以重写 `initServices` 方法来注册服务。

```dart
class _MyStatefulWidgetState extends MvcWidgetState<MyStatefulWidget> {
  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
    collection.addSingleton<SomeService>((_) => SomeService());
  }
  // ...
}
```

## 获取依赖

### 1. 在服务内部获取 (`DependencyInjectionService`)

任何类只要混入 (`with`) `DependencyInjectionService`，就可以通过 `getService<T>()` 方法来获取其他已注册的服务。

```dart
class MyService with DependencyInjectionService {
  void doSomething() {
    // 假设 ApiService 已经被注册
    final ApiService api = getService<ApiService>();
    api.fetchData();
  }
}
```

**重要提示**：一个混入了 `DependencyInjectionService` 的对象必须**通过依赖注入系统被创建和获取**，它才能正确关联到一个作用域。直接通过构造函数 `MyService()` 创建的实例是“游离”的，调用 `getService` 会失败。

```dart
// 正确的做法
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<ApiService>((_) => ApiService());
    collection.addSingleton<MyService>((_) => MyService());
  },
  child: Builder(
    builder: (context) {
      // 必须从 DI 容器中获取 MyService 实例
      context.getMvcService<MyService>().doSomething(); // OK
      
      // 错误的做法
      // MyService().doSomething(); // 这会 Crash，因为它没有关联到任何作用域
      
      return Container();
    },
  ),
);
```

-   `MvcController` 和 `MvcView` 已经混入了 `DependencyInjectionService`，所以你可以直接在它们内部使用 `getService<T>()`。
-   默认情况下，`MvcController` 是其作用域内的**单例**，而 `MvcView` 是**瞬时**的。

### 2. 通过 `BuildContext` 获取

在 Widget 的 `build` 方法中，最常见的获取服务的方式是通过 `BuildContext` 的扩展方法：

```dart
// 获取服务，如果找不到会抛出异常
final SomeService service = context.getMvcService<SomeService>();

// 尝试获取服务，如果找不到返回 null
final SomeService? service = context.tryGetMvcService<SomeService>();
```

`context.getMvcService<T>()` 会从当前 `BuildContext` 开始，沿着 Widget 树向上查找最近的 `MvcWidget`，并从其对应的作用域中获取服务。

**作用域规则**：你只能获取在**当前作用域或其祖先作用域**中注册的服务。尝试获取在子作用域中注册的服务将会失败。

```dart
Builder(
  builder: (context) {
    // 错误：此时 SomeService 尚未在可访问的作用域中注册
    // context.getMvcService<SomeService>(); // 这会抛出异常

    return MvcDependencyProvider(
      provider: (collection) {
        collection.addSingleton<SomeService>((_) => SomeService());
      },
      child: Builder(
        builder: (context) {
          // 正确：现在 SomeService 在当前作用域中是可用的
          final someService = context.getMvcService<SomeService>();
          return Container();
        },
      ),
    );
  },
);
```
