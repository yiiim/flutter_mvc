# Dependency Injection

`flutter_mvc` includes a powerful Dependency Injection (DI) system built on the `dart_dependency_injection` package and deeply integrated with Flutter's widget lifecycle. DI is the core mechanism for managing the creation and lifecycle of objects (services) in your application.

## Service Lifetime Types

You can register services with one of three lifetime types:

**1. Singleton**
Registered using the `addSingleton` method. Only one instance of the service is created within the **scope where it is registered and all its child scopes**. All requests for this service will return the same instance.

**2. Transient**
Registered using the `addTransient` or `add` method. A new instance is created **each time** it is requested.

**3. Scoped**
Registered using the `addScoped` method. Multiple requests for the service within the **same scope** will return the same instance, but requests from **different scopes** will return different instances.

## Dependency Injection Scopes

`flutter_mvc` tightly couples the widget tree with a dependency injection scope tree.

-   Each `MvcWidget` (including `Mvc`, `MvcStatelessWidget`, `MvcStatefulWidget`) creates a new dependency injection scope.
-   This forms a **scope tree** that parallels the widget tree.
-   Child scopes can access services registered in their parent scopes.
-   If a service of the **same type** is registered in a child scope as in a parent scope, the service in the child scope will **override** the one in the parent scope. When the service is requested in that child scope or its descendants, the instance from the child scope will be retrieved.

**Example: Scope Overriding**
```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<SomeService>((_) => SomeService("Root"));
  },
  child: MvcDependencyProvider( // Creates a child scope
    provider: (collection) {
      // Overrides SomeService in the child scope
      collection.addSingleton<SomeService>((_) => SomeService("Child"));
    },
    child: Builder(
      builder: (context) {
        // Getting SomeService will retrieve the "Child" instance from the child scope
        final someService = context.getService<SomeService>();
        return Text(someService.name); // Displays "Child" on the screen
      },
    ),
  ),
);
```

## Ways to Inject Dependencies

There are several ways to register services in a scope:

### 1. `MvcDependencyProvider`

This is a widget specifically designed for providing dependencies. It creates a new scope in its subtree and registers services via the `provider` callback.

```dart
MvcDependencyProvider(
  provider: (collection) {
    // Register a singleton service
    collection.addSingleton<ApiService>((_) => ApiService());
    // Register a transient service
    collection.add<TempService>((_) => TempService());
    // Register a scoped service
    collection.addScoped<ScopedService>((_) => ScopedService());
  },
  child: MyApp(),
);
```

### 2. `MvcController`

In an `MvcController`, you can override the `initServices` method to register services. These services are available within the scope of the `Mvc` widget associated with this controller.

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

In its corresponding `MvcWidgetState`, you can also override the `initServices` method to register services.

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

## Retrieving Dependencies

### 1. Inside a Service (`DependencyInjectionService`)

Any class that mixes in `with DependencyInjectionService` can retrieve other registered services using the `getService<T>()` method.

```dart
class MyService with DependencyInjectionService {
  void doSomething() {
    // Assuming ApiService has been registered
    final ApiService api = getService<ApiService>();
    api.fetchData();
  }
}
```

**Important Note**: An object that mixes in `DependencyInjectionService` must be **created and retrieved through the dependency injection system** to be correctly associated with a scope. An instance created directly via its constructor, like `MyService()`, is "detached" and calling `getService` on it will fail.

```dart
// Correct way
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<ApiService>((_) => ApiService());
    collection.addSingleton<MyService>((_) => MyService());
  },
  child: Builder(
    builder: (context) {
      // The MyService instance must be retrieved from the DI container
      context.get<MyService>().doSomething(); // OK
      
      // Incorrect way
      // MyService().doSomething(); // This will crash because it's not associated with any scope
      
      return Container();
    },
  ),
);
```

-   `MvcController` and `MvcView` already mix in `DependencyInjectionService`, so you can use `getService<T>()` directly within them.
-   By default, `MvcController` is a **singleton** within its scope, while `MvcView` is **transient**.

### 2. Via `BuildContext`

In a widget's `build` method, the most common way to retrieve a service is through `BuildContext`'s extension methods:

```dart
// Get a service; throws an exception if not found
final SomeService service = context.getService<SomeService>();

// Try to get a service; returns null if not found
final SomeService? service = context.tryGetService<SomeService>();
```

`context.getService<T>()` starts from the current `BuildContext` and searches up the widget tree for the nearest `MvcWidget`, then retrieves the service from its corresponding scope.

**Scope Rule**: You can only retrieve services registered in the **current scope or its ancestor scopes**. Attempting to retrieve a service registered in a child scope will fail.

```dart
Builder(
  builder: (context) {
    // Error: SomeService is not yet registered in an accessible scope
    // context.getService<SomeService>(); // This will throw an exception

    return MvcDependencyProvider(
      provider: (collection) {
        collection.addSingleton<SomeService>((_) => SomeService());
      },
      child: Builder(
        builder: (context) {
          // Correct: SomeService is now available in the current scope
          final someService = context.get<SomeService>();
          return Container();
        },
      ),
    );
  },
);
```
