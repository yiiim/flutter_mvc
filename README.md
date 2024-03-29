[English，[中文](README_CN.md)]

# Quick Start

## Using MVC

Create `model`, `view`, `controller`

```dart

class HomeModel {
  const HomeModel(this.title);
  final String title;
}

class HomeController extends MvcController<HomeModel> {
  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Center(
      child: Text(controller.model.title),
    );
  }
}

```

Using Mvc in Flutter

```dart
Mvc(
  create: () => HomeController(),
  model: const HomeModel('Flutter Mvc Demo'),
)
```

This will display the text `Flutter Mvc Demo`.

>If you don't need a Model, you can omit it.

## Updating MVC

```dart
class _MyHomePageState extends State<MyHomePage> {
  String title = 'Flutter Mvc Demo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Mvc(
        create: () => HomeController(),
        model: HomeModel(title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            title = 'Flutter Mvc Demo Updated';
          });
        },
        tooltip: 'Update Title',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

After clicking the button, the `title` of `HomeModel` will be updated, and `HomeView` will also be updated.

## Controller Lifecycle

```dart
class HomeController extends MvcController<HomeModel> {
  @override
  void init() {
    super.init();
  }

  @override
  void didUpdateModel(HomeModel oldModel) {
    super.didUpdateModel(oldModel);
  }

  @override
  void activate() {
    super.activate();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}
```

The `Controller` lifecycle is consistent with the `State` lifecycle in `StatefulWidget`.

## Updating Widget

### Updating MvcView

```dart
class HomeController extends MvcController {
  String title = "Default Title";

  void tapUpdate() {
    title = "Title Updated";
    update();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Center(
        child: Text(controller.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapUpdate,
        tooltip: 'Update Title',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Using the `update` method in `Controller` can update the entire `MvcView`.

### Update Specific Widget With Widget Type

```dart
class HomeController extends MvcController {
  String title = "Default Title";
  String body = "Default Body";

  void tapUpdate() {
    title = "Title Updated";
    body = "Body Updated";
    querySelectorAll<MvcHeader>().update(); // update all MvcHeader, or use querySelectorAll("MvcHeader").update();
    querySelectorAll("MvcBody,MvcHeader").update(); // update all MvcBody and MvcHeader
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MvcHeader(
            builder: (_) => Text(controller.title),
          ),
          MvcBody(
            builder: (_) => Text(controller.body),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapUpdate,
        tooltip: 'Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Not all Widgets can be updated with type, only Widgets that extend from `MvcStatelessWidget` or `MvcStatefulWidget` can be updated with type.

```dart
class MyMvcWidget extends MvcStatelessWidget<HomeController> {
  const MyMvcWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text((context as MvcContext<HomeController>).controller.title);
  }
}

class HomeController extends MvcController {
  String title = "Default Title";

  void tapUpdate() {
    title = "Title Updated";
    querySelectorAll<MyMvcWidget>().update(); // update all MyMvcWidget. or use querySelectorAll("MyMvcWidget").update();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MyMvcWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapUpdate,
        tooltip: 'Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Update Specific Widget with id, class, attribute

```dart
class HomeController extends MvcController {
  String title = "Default Title";

  void tapUpdateById() {
    querySelectorAll('#title_id').update(() => title = "Title Updated By Id");
  }

  void tapUpdateByClass() {
    querySelectorAll('.title_class').update(() => title = "Title Updated By Class");
  }
  void tapUpdateByAttribute() {
    querySelectorAll('[data-title]').update(() => title = "Title Updated By Attribute");
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MvcBuilder(
            id: "title_id",
            classes: const ["title_class"],
            attributes: const {"data-title": "title"},
            builder: (_) {
              return Text(controller.title);
            },
          ),
          TextButton(
            onPressed: controller.tapUpdateById,
            child: const Text("Update By Id"),
          ),
          TextButton(
            onPressed: controller.tapUpdateByClass,
            child: const Text("Update By Class"),
          ),
          TextButton(
            onPressed: controller.tapUpdateByAttribute,
            child: const Text("Update By Attribute"),
          ),
        ],
      ),
    );
  }
}
```

`querySelectorAll` follows the [web selector rules](https://www.w3.org/TR/selectors-4). It can be used to update multiple widgets that meet the rules at the same time, but it does not support sibling selectors.

There is also a static method: `Mvc.querySelectorAll`, which can update the widgets on the current widget tree anywhere.

## Dependency Injection

Dependency injection is a core feature of flutter_mvc. It allows you to easily get the objects you need in the framework.

### Overview

In the dependency injection of flutter_mvc, you only need to provide the object type and the method of creating the object. The framework will automatically create the object and provide it to you when needed. It also provides three different lifecycles: `singleton mode`, `transient mode`, `scope mode`.

Singleton mode, the object will only be created once, and the same object will be returned for subsequent acquisitions.

```dart
collection.addSingleton<TestService>((_) => TestService());
```

Transient mode, a new object will be created every time it is obtained.

```dart
collection.add<TestService>((_) => TestService());
```

Scope mode, a new object will be created every time it is obtained, but the objects obtained in the same scope are the same.

```dart
collection.addScopedSingleton<TestService>((_) => TestService());
```

The scope mode is a very important concept in flutter_mvc. It allows you to get the same object in the same scope, but the objects obtained in different scopes are different. **And even if it is in singleton mode, if the scope that injects the object is destroyed, the object will also be destroyed.**

---

**In flutter_mvc, every widget that extend from `MvcStatefulWidget` and `MvcStatelessWidget` is a new scope, including `Mvc`, `MvcBuilder`, `MvcHeader`, `MvcBody`, `MvcFooter`, `MvcServiceScope`, etc.**

Inject the following objects:

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService1>((_) => TestService1());
    collection.add<TestService2>((_) => TestService2());
    collection.addScopedSingleton<TestService3>((serviceProvider) => TestService3());
  },
  child: Mvc(create: () => HomeController()),
)
```

Get objects:

```dart
class HomeController extends MvcController {
  @override
  void init() {
    super.init();
    final TestService1 service1 = getService<TestService1>();
    final TestService2 service2 = getService<TestService2>();
    final TestService3 service3 = getService<TestService3>();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    final TestService1 service1 = getService<TestService1>();
    final TestService2 service2 = getService<TestService2>();
    final TestService3 service3 = getService<TestService3>();

    return Scaffold(
      body: Center(
        child: MvcBuilder(
          builder: (context) {
            final TestService1 service1 = context.getService<TestService1>();
            final TestService2 service2 = context.getService<TestService2>();
            final TestService3 service3 = context.getService<TestService3>();
            return const Text("Hello, World!");
          },
        ),
      ),
    );
  }
}
```

All `TestService2` are not the same instance because it is in transient mode.

All `TestService1` are the same instance because it is in singleton mode.

The `TestService3` obtained in `Controller` and `MvcView` is the same instance because `Controller` and `MvcView` belong to the same scope. However, the `TestService3` obtained through its `context` in `MvcBuilder` is a new instance because `MvcBuilder` is a new scope.

Let's look at another example:

```dart
MvcDependencyProvider(
  key: const ValueKey('1'),
  provider: (collection) {
    collection.addSingleton<TestService1>((_) => TestService1());
    collection.add<TestService2>((_) => TestService2());
    collection.addScopedSingleton<TestService3>((serviceProvider) => TestService3());
  },
  child: Column(
    children: [
      MvcDependencyProvider(
        key: const ValueKey('2'),
        provider: (collection) {
          collection.addSingleton<TestService4>((_) => TestService4());
          collection.add<TestService5>((_) => TestService5());
          collection.addScopedSingleton<TestService6>((serviceProvider) => TestService6());
        },
        child: Mvc(create: () => HomeController()),
      ),
      MvcDependencyProvider(
        key: const ValueKey('3'),
        provider: (collection) {
          collection.addSingleton<TestService7>((_) => TestService7());
          collection.add<TestService8>((_) => TestService8());
          collection.addScopedSingleton<TestService9>((serviceProvider) => TestService9());
        },
        child: Mvc(create: () => HomeController()),
      )
    ],
  ),
)
```

Key2 and Key3 belong to two different scopes, they have a common parent scope Key1.

`TestService2` is a transient mode in the parent level of Key1, and it is always a new instance when obtained.

`TestService1` is a singleton mode in the parent level of Key1, and it is the same instance when obtained in Key2 and Key3 and their sublevels.

`TestService3` is a scoped mode in the parent level of Key1, and it is different instances when obtained in Key2 and Key3, but it is the same instance when obtained multiple times in Key2 or Key3 or obtained in their sublevels.

`TestService7`, `TestService8`, and `TestService9` cannot be obtained in Key1 because they and their parents have not injected these objects, similarly, `TestService4`, `TestService5`, and `TestService6` cannot be obtained in Key2.

---

For more features about dependency injection, you can refer to [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection), there are more interesting uses inside.

### Injecting Objects

There are many ways to inject objects.

As mentioned earlier, use `MvcDependencyProvider` to inject objects.

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: const MyApp(),
)
```

---

Inject objects in `Controller`.

```dart
class HomeController extends MvcController {
  @override
  void initServices(ServiceCollection collection, ServiceProvider parent) {
    super.initServices(collection, parent);
    collection.addSingleton<TestService>((_) => TestService());
  }
}
```

---

Use `MvcStatefulWidget` to inject objects.

```dart
class TestMvcStatefulWidget extends MvcStatefulWidget {
  MvcWidgetState createState() => TestMvcStatefulState();
}
class TestMvcStatefulState extends MvcWidgetState {
  @override
  void initServices(ServiceCollection collection, ServiceProvider parent) {
    super.initServices(collection, parent);
    collection.addSingleton<TestService>((_) => TestService());
  }
}
```

---

Each `Mvc` has already injected `MvcController` and `MvcView` by default in singleton mode.

### Getting Objects

When getting objects, you can get the objects injected in the current scope and all its parent scopes.

Any object injected through dependency injection can be obtained by mixing in `DependencyInjectionService` and then using the `getService` method. In flutter_mvc, `MvcController`, `MvcView`, `MvcWidgetState` all meet this condition. You can also get it through the injected object, for example:

```dart
class TestService with DependencyInjectionService {
  void test() {
    final HomeController controller = getService<HomeController>();
    controller.update();
  }
}
```

As the above code shows, you can get the `Controller` you want in the injected object at any time, but please be sure to pay attention to the scope.

---

You can also get objects through context.

```dart
class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            final TestService service = context.getMvcService<TestService>();
            return const Text("Hello, World!");
          },
        ),
      ),
    );
  }
}
```

The scope of context acquisition is the scope where the nearest MvcWidget in the current context is located.

### Object Lifecycle

The lifecycle methods of objects are limited to objects that mix in `DependencyInjectionService`.

---

- Initialization

When an object is created, `dependencyInjectionServiceInitialize` will be executed immediately and synchronously, and each instance will only be executed once. This method can be asynchronous. When `dependencyInjectionServiceInitialize` is an asynchronous method, after getting the object, you can use `await waitLatestServiceInitialize()` or `await waitServicesInitialize()` to wait for initialization to complete. `waitLatestServiceInitialize` only waits for the initialization of the most recently obtained object in the current run loop to complete, and `waitServicesInitialize` waits for all current initializations to complete.

---

- Destruction

When the scope where the object is located is destroyed, the `dispose` method of the object **created by this scope** will be executed. An exception is if the object is in transient mode, it may be cleared by GC at any time when it is not in use, and its `dispose` method will not be executed.

### Using Dependency Injection Objects to Update Widgets

If the injected object mixes in `MvcService`, then you can use some methods to update the widget.

---

Use `MvcServiceScope`

```dart
class TestService with DependencyInjectionService, MvcService {
  String title = "title";
  void test() {
    update(() => title = "new title");
  }
}
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: Scaffold(
    body: MvcServiceScope<TestService>(
      builder: (MvcContext context, TestService service) {
        return Text(service.title);
      },
    ),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<TestService>().test();
          },
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
)
```

Clicking the button will update the content of `Text`.

---

If you have an `MvcContext`, you can also depend it on the object.

```dart
class TestService with DependencyInjectionService, MvcService {
  String title = "title";
  void test() {
    update(() => title = "new title");
  }
}

class TestWidget extends MvcStatelessWidget {
  const TestWidget({super.key, super.id, super.classes});

  @override
  Widget build(BuildContext context) {
    return Text((context as MvcContext).dependOnService<TestService>().title);
  }
}

MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: Scaffold(
    body: const TestWidget(),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<TestService>().test();
          },
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
)
```

The `context` in the `build` method of `MvcStatelessWidget` and `MvcWidgetState` can be forcibly converted to `MvcContext`, and the `context` returned by `MvcWidgetState` is also `MvcContext`.

In addition, `MvcService` also has a `querySelectorAll` method, you can use it to find and update widgets. Its search logic is to search with the widget that depends on it as the root node.

```dart
class TestService with DependencyInjectionService, MvcService {
  String title = "title";
  void test() {
    querySelectorAll('#title').update(
      () {
        title = "new title";
      },
    );
  }
}

MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: Scaffold(
    body: MvcServiceScope<TestService>(
      builder: (MvcContext context, TestService service) {
        return Column(
          children: [
            MvcBuilder(
              id: "title",
              builder: (MvcContext context) {
                return Text(service.title);
              },
            ),
          ],
        );
      },
    ),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<TestService>().test();
          },
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
)
```

The above code can also update the content of `Text`.

---

The same `MvcService` can have multiple dependent widgets, and they will all be updated when the `update` method is called. When the `querySelectorAll` method is called, they will be searched separately with them as the root node, and the result is their union.
