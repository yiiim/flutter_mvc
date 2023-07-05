# Flutter Mvc

Language: English | [中文](https://github.com/yiiim/flutter_mvc/blob/master/README-zh.md)

Flutter Mvc is a Flutter framework that includes UI and logic separation, state management, and dependency injection.

- [Getting Started](#getting-started)
- [Mvc](#mvc)
  - [Model](#model)
  - [View](#view)
  - [Controller](#controller)
    - [Creating a Controller](#creating-a-controller)
    - [Creating a Controller without View](#creating-a-controller-without-view)
    - [Controller Lifecycle](#controller-lifecycle)
    - [Accessing Other Controllers](#accessing-other-controllers)
    - [Accessing Controllers from Anywhere](#accessing-controllers-from-anywhere)
    - [MvcControllerPart](#mvccontrollerpart)
- [State Management](#state-management)
  - [Example](#example)
  - [MvcStateScope](#mvcstatescope)
  - [MvcStateProvider](#mvcstateprovider)
  - [MvcStateValue](#mvcstatevalue)
  - [Initializing State](#initializing-state)
  - [Accessing State](#accessing-state)
  - [Updating State](#updating-state)
  - [Removing State](#deleting-state)
  - [Model State](#model-state)
  - [Environment State](#environment-state)
- [Dependency Injection](#dependency-injection)
  - [MvcDependencyProvider](#mvcdependencyprovider)
  - [Accessing Dependencies](#accessing-dependencies)
  - [Service Scope](#service-scope)
  - [initService](#initservice)

## Getting Started

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Mvc<IndexPageController, IndexPageModel>(
        create: () => IndexPageController(),
        model: IndexPageModel(title: "Flutter Demo"),
      ),
    );
  }
}

/// Model
class IndexPageModel {
  IndexPageModel({required this.title});
  final String title;
}

/// View
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ctx.model.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            MvcStateScope<IndexPageController>(
              (state) {
                return Text("${state.get<int>()}");
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctx.controller.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Controller
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0); // Initialize state
  }

  void incrementCounter() {
    updateState<int>(updater: ((state) => state?.value++)); // Update state
  }

  @override
  MvcView view() {
    return IndexPage();
  }
}
```

## Mvc

### Model

In Mvc, there are no restrictions on the Model. It can be of any type, including nullable types. The main purpose of the Model is to pass

 new values during the reconstruction process of `Mvc` and facilitate communication between the View and Controller. The `create` function in `Mvc` is only executed once during mounting and is not re-executed when `Mvc` updates. **Therefore, instead of using the Controller's constructor to pass parameters during construction, you should use the Model to pass the necessary values**. When `Mvc` is externally reconstructed, the Model's state updates are received. For more information on Model state updates, please refer to [this section](#model-state).

### View

The View is returned by the Controller and created using the following pattern:

```dart
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.model.title),
      ),
      body: Center(
        child: Text(context.controller.content),
      ),
    );
  }
}
```

It has two generic parameters: the type of the Model and the type of the Controller. It also includes a `buildView` method that returns the UI.

Inside the `buildView` method, you can access the Controller and Model using the `context` parameter and use them to build the UI.

If you don't need the Model, you can use `MvcModelessView<TControllerType extends MvcController>`, which has only one generic type for the Controller.

```dart
class IndexPage extends MvcModelessView<IndexPageController> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      body: Center(
        child: Text(ctx.controller.content),
      ),
    );
  }
}
```

When using `MvcModelessView`, you won't have access to the model.

### Controller

#### Creating a Controller

Create a subclass of `MvcController` and implement the `view` method to return a `MvcView`.

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
  }

  @override
  MvcView view() {
    return IndexPage();
  }
}
```

When returning the View, make sure the generic types of the returned `MvcView` match the Controller's types.

#### Creating a Controller without View

Create a subclass of `MvcProxyController`.

```dart
class IndexDataController extends MvcProxyController {
  @override
  void init() {
    super.init();
  }
}
```

Use `MvcProxy` to mount a Controller without a View.

```dart
MvcProxy(
    proxyCreate: () => IndexDataController(),
    child: ...,
)
```

`MvcProxyController` doesn't need to return a View but can still provide state to its children. This can be useful in certain situations.

#### Controller Lifecycle

When `Mvc` is mounted, the Controller goes through the following lifecycle:

- After the Controller is created, it performs necessary preparations and then immediately executes the Controller's `init` method.
- When `Mvc` updates, there are no specific lifecycle methods for the Controller. Instead, it triggers Model state updates in the Controller.
- When `Mvc` is unmounted, the `dispose` method is executed.

Avoid passing the same Controller instance to multiple Mvc instances.

#### Accessing Other Controllers

Within a Controller, you can access the parent, sibling, and child Controllers:

```dart
/// Find a Controller of a specific type from the parent level
T? parent<T extends MvcController>() => context.parent<T>();

/// Find a Controller of a specific type among direct children
T? child<T extends MvcController>({bool sort = false}) => context.child<T>(sort: sort);

/// Find a Controller of a

 specific type among all children
T? find<T extends MvcController>({bool sort = false}) => context.find<T>(sort: sort);

/// Find the previous sibling Controller of a specific type
T? previousSibling<T extends MvcController>({bool sort = false}) => context.previousSibling<T>(sort: sort);

/// Find the next sibling Controller of a specific type
T? nextSibling<T extends MvcController>({bool sort = false}) => context.nextSibling<T>(sort: sort);

/// Find a Controller of a specific type among siblings
T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) => context.sibling<T>(sort: sort);

/// Find a Controller by searching forward, which means searching among previous siblings and parent (equivalent to [previousSibling] ?? [parent])
T? forward<T extends MvcController>({bool sort = false}) => context.forward<T>(sort: sort);

/// Find a Controller by searching backward, which means searching among next siblings and children (equivalent to [nextSibling] ?? [find])
T? backward<T extends MvcController>({bool sort = false}) => context.backward<T>(sort: sort);
```

Avoid setting `sort` to `true` unless necessary. Setting `sort` ensures that the Controllers are retrieved in a specific order (based on the order of the multiple child Elements in the slots of the parent Mvc), but it increases performance overhead. If order is not important, the Controllers among siblings are returned in the order of mounting.

#### Accessing Controllers from Anywhere

Using the static method of Mvc, you can retrieve a Controller of a specific type from the entire `Mvc` hierarchy.

```dart
static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where});
```

Here's how you can use it:

```dart
var controller = Mvc.get<IndexPageController>();
```

**context**: If the `context` parameter is provided, it searches for the nearest Controller in the parent hierarchy of that context.

**where**: It allows you to provide a filter when there are multiple Controllers of the specified type. Only Controllers that satisfy the condition specified by the `where` parameter will be returned.

#### MvcControllerPart

When a Controller has a large amount of logic or state, you can extract some independent logic into an `MvcControllerPart`. Here's how you can do it:

Create an `MvcControllerPart`:

```dart
class IndexPageControllerBannerPart extends MvcControllerPart<IndexPageController> {
  @override
  void init() {
    super.init();
  }
}
```

Add the `Part` to the Controller by implementing the `initPart` method:

```dart
@override
void initPart(MvcControllerPartCollection collection) {
  super.initPart(collection);
  collection.addPart(() => IndexPageControllerBannerPart());
}
```

You can add multiple `Parts` to the same Controller, but only one instance of each type can be added.

Retrieve a `Part` from the Controller:

```dart
getPart<IndexPageControllerBannerPart>()
```

Make sure to use the same generic type as used during registration.

---

`Part` has the following characteristics:

- The `init` and `dispose` methods of the `Part` are executed within the `init` and `dispose` methods of the Controller, respectively.

- Each `Part` has access to the Controller it belongs to.

- Each `Part` has its own state, and it can access and manage its state similar to a Controller.

## State Management

### Example

First, initialize the state in the `init` method of the Controller:

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0);
  }
}
```

Use the state in the View:

```dart
Widget buildView(context) {
  return MvcStateScope<IndexPageController>(
    (state) {
      return Text("${state.get<int>()}");
    },
  );
}
```

Update the state in the Controller:

```dart
updateState<int>(updater: ((state) => state.value++));
```

If the `MvcStateScope` has accessed the state before, it will be rebuilt when the state is updated. 

### MvcStateScope

`MvcStateScope` is defined as follows:

```dart
class MvcStateScope<TControllerType extends MvcController> extends Widget {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);

  final Widget Function(MvcWidgetStateProvider state) builder;

  final MvcStateProvider? stateProvider;

  final Widget? child;
}
```

- **builder**: The builder that is rebuilt when the state is updated.

- **stateProvider**: The state provider, typically a `MvcController`. If `stateProvider` is not specified, the nearest `MvcController` of type `TControllerType` will be used as the state provider. If no generic type `TControllerType` is specified, the nearest `MvcController` will be

 used.

- **child**: This parameter allows passing a child widget that doesn't need to be updated when the state changes. It can be accessed through the parameters of the `builder` function, which helps to optimize performance.

The `builder` function receives a `MvcWidgetStateProvider` parameter that allows **accessing all the states provided by the state provider**. Once a state is accessed through it, the widget will be updated **whenever that state is updated**. Even if the state was accessed through a `Builder`, it can still receive updates. Here's an example:

```dart
MvcStateScope<IndexPageController>(
  (MvcWidgetStateProvider state) {
    return Builder(
      builder: (context) {
        return Text("${state.get<int>()}");
      },
    );
  },
)
```

### MvcStateProvider

`MvcStateProvider` is an abstract interface that any class implementing it can use to provide states to `MvcStateScope`. In Mvc, `MvcController` implements this interface. All state-related operations are performed within the `MvcController`.

### MvcStateValue

In Mvc, the type of state is `MvcStateValue<T>`.

```dart
class MvcStateValue<T> extends ChangeNotifier {
  MvcStateValue(this.value);
  T value;

  void update() => notifyListeners();
}
```

It is similar to `ValueNotifier`, but it doesn't send notifications every time `setValue` is called. Instead, it only sends notifications when the `update()` method is called. **The state is updated every time `update()` is called**.

### Initializing State

Method definition:

```dart
MvcStateValue<T> initState<T>(T state, {Object? key})
```

Example usage:

```dart
initState<int>(0)
```

You can use the `initState` method anytime in the Controller to initialize a new state. The state will be stored in the Controller until it is deleted or the Controller is destroyed.

**key**: A unique identifier for the state within the same Controller. The uniqueness of a state is determined by the combination of the generic type and the `key` parameter's hashCode.

### Accessing State

You can access states in the Controller using the following method:

```dart
T? getState<T>({Object? key});
```

Example usage:

```dart
var state = getState<int>();
```

In MvcController, when getting the state, **First get the state in the current Controller. If the state is not obtained from the current Controller, it will be obtained from [Part](#mvccontrollerpart), if the state is not obtained in the Part, it will be obtained from [Environmental State](#environment-state).**

When using `MvcStateScope` to access states, it uses `MvcStateProvider` to retrieve the states. In Mvc, the `MvcController` acts as the `MvcStateProvider`, and `MvcWidgetStateProvider` is a wrapper around `MvcStateProvider`.

If the state doesn't exist, it will return null. However, if the state itself is null, you can use the `getStateValue` method to retrieve the returned `MvcStateValue`. If the `MvcStateValue` is null, it means the state wasn't found. If the `MvcStateValue` is not null, its `value` property represents the state value.

### Updating State

```dart
MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key})
```

Example usage:

```dart
updateState<int>(updater: (state) => state.value++);
```

- **updater**: This method allows you to set a new value for the state. Even

 if you don't set a new value, it will trigger a state update.

- **key**: Similar to accessing states, this parameter is used to identify the state to be updated.

When called in the Controller, if the state to be updated is not found, it returns null. Only the states created by the Controller itself can be updated.

### Deleting State

```dart
void deleteState<T>({Object? key});
```

This method is also called in the Controller. Only the states created by the Controller itself can be deleted.

### Model State

In the Controller, you can directly use the `model` property to access the Model. The Model is a state with a null key and the generic type `TModelType`. You can also access the Model state using the state access methods. The Model state will be updated when the `Mvc` it belongs to is externally rebuilt.

To get the Model state:

```dart
var model = getState<TModelType>();
```

If there are UI components in the View that depend on external Model updates, you can update the UI by accessing the Model state.

```dart
MvcStateScope<IndexPageController>(
    (MvcWidgetStateProvider state) {
        return Text("${state.get<TModelType>()}");
    },
)
```

### Environment State

In addition to using the Controller to operate the state, you can also use the ```environment``` attribute of the Controller to operate the state. The state of the ```environment``` can be obtained by all children of the current Mvc.

The ```environment``` operates in the same way as the Controller.

## Dependency Injection

Dependency injection is implemented using [https://github.com/yiiim/dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection).

It is recommended to read the [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection) documentation before reading the following document.

### MvcDependencyProvider

Use the `MvcDependencyProvider` to inject dependencies into child components.

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<Object>((serviceProvider) => Object());
    collection.addScopedSingleton<Object>((serviceProvider) => Object());
    collection.add<Object>((serviceProvider) => Object());
  },
  child: ...,
);
```

- `addSingleton`: Injects a singleton, which means all child components that request this type of dependency will receive the same instance.

- `addScopedSingleton`: Injects a scoped singleton. In Mvc, each Mvc has its own scoped services. With this type of dependency, different instances will be provided in different Controller instances, but within the same Controller instance, the same instance will be provided.

- `add`: Injects a regular service. Each request for this dependency will create a new instance.

You can also inject `MvcController` and when using `Mvc`, there's no need to pass the `create` parameter. `Mvc` will create the Controller from the dependency injection.

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addController<IndexPageController>((provider) => IndexPageController());
  },
  child: Mvc<IndexPageController,IndexPageModel>(model: IndexPageModel()),
);
```

### Accessing Dependencies

The `MvcController` within the `MvcDependencyProvider` can use the `DependencyInjectionService` mixin to access the injected services.

```dart
T getService<T extends Object>();
```

### Service Scope

Each `MvcController` creates a service scope using its parent `MvcController`'s scope during creation. If there's no parent, it uses the `MvcOwner`. By default, the service scope registers three types of singleton services: `MvcController`, `MvcContext`, and `MvcView`. `MvcController` refers to the Controller itself, `MvcContext` refers to the `Element` in which the Controller exists, and `MvcView` is created using the Controller. The service scope is released when the Controller is destroyed.

## initService

```dart
@override
void initService(MvcServiceCollection collection) {
    collection.add<Object>((serviceProvider) => Object());
}
```

By overriding the `initService` method in the Controller, you can inject additional services into the service scope of the current Controller.

For more usage examples of dependency injection, please refer to the [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection) documentation.