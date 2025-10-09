# Dependency Injection

## Dependency Injection Service Types

**Singleton Services**: Injected through the `addSingleton` method, only one instance will be created within this scope and child scopes, and all requests for this service will get the same instance.

**Transient Services**: Injected through the `addTransient` method, a new instance will be created for each request.

**Scoped Services**: Injected through the `addScoped` method, one instance will be created per scope. Requests within the same scope will get the same instance, but requests from different scopes will get different instances.

## Dependency Injection Scopes

`flutter_mvc` uses dependency injection to manage objects and Widgets. Each `MvcWidget` has a dependency injection scope, so `MvcWidget`s in the widget tree form a dependency injection scope tree. Each scope can register its own services and can access services from parent scopes. Child scopes can register services that are already registered in parent scopes, in which case the child scope's service will override the parent scope's service. If a singleton injected in the parent scope is overridden by a child scope, then the singleton service obtained in the child scope will be the instance from the child scope, not the parent scope.

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
          return Text(someService.name); // Output "Child"
        },
      ),
    ),
  ),
);
```

## Ways to Inject Dependencies

### MvcDependencyProvider

`MvcDependencyProvider` is a Widget used to provide dependency injection services in its subtree. You can register various services here, which can be singleton, transient, or scoped services.

```dart
MvcDependencyProvider(
  provider: (collection) {
    // Register a singleton service
    collection.addSingleton<ApiService>((_) => ApiService());
    // Register a transient service
    collection.addTransient<TempService>((_) => TempService());
    // Register a scoped service
    collection.addScoped<ScopedService>((_) => ScopedService());
  },
  child: MyApp(),
);
```

### MvcController

`MvcController` can also register services by overriding the `initServices` method:

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

`MvcStatefulWidget` can also register services by overriding the `initServices` method:

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

## Getting Dependencies

### DependencyInjectionService

Any service registered through dependency injection can use `with DependencyInjectionService` and then obtain other services through the `getService<T>()` method:

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

When a service uses `with DependencyInjectionService` and is obtained through getService, the service will automatically be associated with a scope. For scoped and transient services, their scope depends on the scope that obtained them. For singleton services, their scope is always in the scope where they were registered. The `getService<T>()` method will obtain services based on the scope associated with the current service.

Both `MvcController` and `MvcView` already mix in `DependencyInjectionService`, so you can directly use the `getService<T>()` method to get services in them.

> `MvcController` is a singleton service in the current scope, and `MvcView` is a transient service in the current scope.

### Getting through Context

You can also get services through `BuildContext`:

```dart
final SomeService service = context.getMvcService<SomeService>();
// or
final SomeService? service = context.tryGetMvcService<SomeService>();
```

The context will look for the nearest `MvcWidget` in the ancestor tree to get services, and the scope for getting services is the scope where this `MvcWidget` is located.

When getting services, you must pay attention to the scope you are in. For example, you should not get services registered in child scopes from parent scopes, because parent scopes cannot access services in child scopes.

For example, in the following code, find1 will throw an exception because SomeService is registered in a child scope and the parent scope cannot access it; while find2 can normally get the SomeService instance.

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

## Associating Services with Widgets

By making your injected service `with MvcWidgetService`, you can associate the service with the Widget of the scope that created this service. This allows you to access its context or update the Widget, and get its `activate` and `deactivate` lifecycle methods.

```dart
class MyService with MvcWidgetService {
  void test() {
    final size = context.size; // Use context
    update(); // Update the associated Widget
  }

  @override
  void mvcWidgetActivate() {}

  @override
  void mvcWidgetDeactivate() {}
}
```

This is usually dangerous, you need to clearly understand the scope where your service is located, and when accessing context, you cannot ensure that the context is still valid. Fortunately, memory is safe, and the service will be destroyed when the Widget is destroyed.

More dangerously, if your service misses `activate` and `deactivate` before initialization, there is no compensation.

If you only need to get context, it is recommended to use `with DependencyInjectionService`, then get `MvcContext` through `getService<MvcContext>()`. The `context` obtained this way is the same as the `context` in `MvcWidgetService`. You should usually not save references to `context` unless you really remember to clean it up in `dispose`.