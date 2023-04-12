# Flutter Mvc

Language: English | [中文](https://github.com/yiiim/flutter_mvc/blob/master/README-zh.md)

Flutter Mvc is a Flutter framework that includes UI and logic separation, state management, and dependency injection. 

## Quick Start

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
    initState<int>(0); // 初始化状态
  }

  void incrementCounter() {
    updateState<int>(updater: ((state) => state?.value++)); // 更新状态
  }

  @override
  MvcView view(model) {
    return IndexPage();
  }
}
```

## Mvc

### Model

In Mvc, there are no restrictions on the Model, which can be of any type or even null. The main role of the Model is to pass new values when the `Mvc` is rebuilt from outside, and it must be passed through the Model. The `create` method of `Mvc` is only executed once when it is mounted, and the Controller is not recreated when `Mvc` is updated. **Therefore, do not use the Controller constructor to pass parameters that need to be updated during construction, but use the Model to pass them**. When the `Mvc` is rebuilt from outside, the Model status update will be received. For information on Model status updates, please refer to [this](#model-state).

### View

The View is returned by the Controller and created as follows:

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

It has two generic parameters, one for the Model type and one for the Controller type, and a `buildView` method that returns the UI.

In the `buildView` method, the Controller and Model can be obtained through the `context` parameter and used to build the UI.

If a complicated Model is not needed, `MvcModelessView<TControllerType extends MvcController>` can be used, which only has a Controller generic type.

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

If `MvcModelessView` is used, the Model cannot be accessed.

### Controller

#### Creating a Controller

Inherited from `MvcController`, the `view` method is implemented to return an `MvcView`.

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
  }

  @override
  MvcView view(model) {
    return IndexPage();
  }
}
```

When returning the View, the generic Controller and Model types of the returned `MvcView` must match those of the Controller.

#### Getting Other Controllers

In the Controller, you can obtain the parent, sibling, and child Controllers.

```dart
/// Find a specified type of Controller from the parent
T? parent<T extends MvcController>() => context.parent<T>();

/// Find a specified type of Controller in the immediate children
T? child<T extends MvcController>({bool sort = false}) => context.child<T>(sort: sort);

/// Find a specified type of Controller from all children
T? find<T extends MvcController>({bool sort = false}) => context.find<T>(sort: sort);

/// Find the previous Controller among siblings
T? previousSibling<T extends MvcController>({bool sort = false}) => context.previousSibling<T>(sort: sort);

/// Find the next Controller among siblings
T? nextSibling<T extends MvcController>({bool sort = false}) => context.nextSibling<T>(sort: sort);

/// Find a Controller among siblings
T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) => context.sibling<T>(sort: sort);

/// Search forward, meaning to search for siblings before and parents,
T? forward<T extends MvcController>({bool sort = false}) => context.forward<T>(sort: sort);

/// Search backward, meaning to search for siblings after and children,
T? backward<T extends MvcController>({bool sort = false}) => context.backward<T>(sort: sort);
```

Unless necessary, do not pass ```true``` for ```sort```. ```sort``` can ensure the order in which Controllers of the same level are obtained when obtaining same-level Controllers (sorted by the slot order of multiple sub-elements under the Mvc), but it will increase performance consumption. If the order is not guaranteed, the same-level Controllers are sorted by the mounting order.

#### Getting Controllers from Anywhere

You can use the static method of ```Mvc``` to obtain Controllers of a specific type from all current ```Mvc```s.

```dart
static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where});
```

Usage:

```dart
var controller = Mvc.get<IndexPageController>();
```

**context**: If the ```context``` parameter is passed in, find the nearest Controller in its parent context.

**where**: If there are multiple Controllers of the same type, use this parameter to filter.

#### MvcControllerPart

When there is a lot of logic or state in the Controller, you can move some independent logic into ```MvcControllerPart```. Usage:

Create an ```MvcControllerPart```:

```dart
class IndexPageControllerBannerPart extends MvcControllerPart<IndexPageController> {
  @override
  void init() {
    super.init();
  }
}
```

Add a ```Part``` to the Controller, implement the ```buildPart``` method, and add it in the ```buildPart``` method:

```dart
@override
void buildPart(MvcControllerPartCollection collection) {
  super.buildPart(collection);
  collection.addPart<IndexPageControllerBannerPart>(() => IndexPageControllerBannerPart());
}
```

Multiple ```Part```s can be added to the same Controller, but only one of the same type can be added.

Get the ```Part``` from the Controller:

```dart
part<IndexPageControllerBannerPart>()
```

The generic type used for retrieval must be consistent with the one used for registration.

---

```Part``` has the following characteristics:

* The ```init``` and ```dispose``` methods of ```Part``` are executed after the Controller.

* Each ```Part``` can obtain the Controller to which it belongs.

* Each ```Part``` has its own state. Using the state in the ```Part``` is similar to using it in the Controller. For documentation on ```Part``` state, see here: [StatePart](#statepart).

## State Management

### Example

First, initialize the state in the ```init``` method of the Controller:

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

If the ```MvcStateScope``` has obtained the state before, it will be rebuilt when updating the state.

### MvcStateScope

The definition of ```MvcStateScope``` is as follows:

```dart
class MvcStateScope<TControllerType extends MvcController> extends Widget {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);

  final Widget Function(MvcWidgetStateProvider state) builder;

  final MvcStateProvider? stateProvider;

  final Widget? child;
}
```

**builder**: The builder that is rebuilt when the state is updated.

**stateProvider**: The state provider, usually a ```MvcController```. If it is null, the state provider is the nearest type to ```TControllerType``` in ```MvcStateScope```.

**child**: When the state is updated, if there are Widgets that do not need to be updated, pass them through this parameter. You can get it through the parameter in the ```builder``` method to save performance.

The parameter ```MvcWidgetStateProvider``` in the ```builder``` method can **obtain all the states provided by the state provider**, and once **the state obtained through it is updated, the Widget will be updated**. Even the state obtained through ```Builder``` can be updated, as shown below:

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

The definition of the state provider ```MvcStateProvider``` is as follows:

```dart
abstract class MvcStateProvider {
  T? getState<T>({Object? key});

  MvcStateValue<T>? getStateValue<T>({Object? key});
}
```

It is an abstract interface. Any class that implements this interface can provide a state for ```MvcStateScope```. In Mvc, ```MvcController``` implements this interface. State-related operations are all performed in ```MvcController```.

### MvcStateValue

In Mvc, the type of the state is ```MvcStateValue<T>```.

```dart
class MvcStateValue<T> extends ChangeNotifier {
  MvcStateValue(this.value);
  T value;

  void update() => notifyListeners();
}
```

It is a class similar to ```ValueNotifier```, but it does not send notifications every time it receives ```setValue```. It only sends them when the ```update()``` method is called. Here, you can understand that **the state is updated every time ```update()``` is called**.

### Initialize State

Method definition:

```dart
MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public})
```

Example:

```dart
initState<int>(0)
```

```initState``` can be used at any time in the Controller to initialize a new state. The state will be saved in the Controller until it is deleted or the Controller is destroyed.

**key**: State identification. **In the same Controller, states rely on the hashCode of the generic type + ```key``` to distinguish uniqueness**.

**accessibility**: Access level of the state:

```dart
enum MvcStateAccessibility {
  /// Global
  global,

  /// Public
  public,

  /// Private
  private,

  /// Internal
  internal,
}
```

* global: Any Controller can obtain this state.
* public: The current Controller and its children can obtain this state. It defaults to public.
* private: The current Controller and its ControllerPart can obtain this state.
* internal: Only the creator of the state can obtain this state.

Only one state in the same Controller instance can be initialized once. The same hashCode of the generic type and key means the same state.

### Obtain State

You can obtain the state in the Controller using the following method:

```dart
T? getState<T>({Object? key, bool onlySelf = false});
```

Example:

```dart
var state = getState<int>()
```

When obtaining state, the key and state type used during initialization are used to look up the state. The lookup not only searches for the state initialized by the current controller but also sequentially searches for states with access levels of "public" or higher in its parent controllers. If the search still finds nothing at the top level, it will then search for all states with an access level of "global" in all current controllers. In simple terms, all accessible states can be obtained.

When using `MvcStateScope` to obtain state, it is obtained through `MvcStateProvider`, which is implemented by `MvcController`. `MvcWidgetStateProvider` is a wrapper for `MvcStateProvider`.

If the state does not exist, `null` is returned. But if the state itself is null, you can use the `getStateValue` method to get the returned `MvcStateValue`. If `MvcStateValue` is null, it means that the state was not obtained; but if `MvcStateValue` is not null, its `value` attribute is the state value.

### Updating State

```dart
MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key})
```

Example usage:

```dart
updateState<int>(updater:(state)=>state.value++);
```

In this method, the `updater` can set the state to a new value. Even if you don't set it, it will trigger a state update.

The `key` is the same as when obtaining state - it is the identifier of the state to be updated.

If called in the controller and the state to be updated is not found, `null` is returned. Only states created by itself can be updated.

### Deleting State

```dart
void deleteState<T>({Object? key});
```

This method can also be called in the controller, but only states created by itself can be deleted.

### StatePart

When using a key and type as the unique identifier of state and when there are too many states of the same type, it may be necessary to create many keys, leading to messy code. To alleviate this situation, an interface for state provision with Parts is provided:

```dart
abstract class MvcHasPartStateProvider extends MvcStateProvider {
  T? getStatePart<T extends MvcStateProvider>();
}
```

This interface returns another state provider based on the type.

`MvcController` also implements this interface. In each `Part` state provider returned by `MvcController`, independent states with the same type and key are initialized. This means that the same type and key of state can be initialized in each `Part`. However, only states with access level "internal" can be initialized in `Part`, and states with "internal" access level can only be obtained through themselves. Therefore, when obtaining the state in `Part`, you need to get the `Part` first, and then get the state. When getting `Part` in `MvcController`, it searches from itself to its parent until it finds the specified type of `Part`. The method for obtaining state in `Part` is defined as follows:

```dart
getStatePart<TPartType>().getState<TStateType>(key:key)
```

Usage example:

```dart
indexPageController.getStatePart<IndexPageControllerBannerPart>().getState<int>(key:IndexPageControllerBannerPartKeys.bannerIndex)
```

It starts searching for the type `TPartType` from the current controller and then gets the state using `TPartType`. If the state is not found in `TPartType`, it will be passed to the `MvcController` to search.

In `MvcStateScope`, it can be used as follows:

```dart
state.part<IndexPageControllerBannerPart>().get<int>(key:IndexPageControllerBannerPartKeys.bannerIndex)
```

This is only valid when the `MvcStateProvider` used by `MvcStateScope` implements `MvcHasPartStateProvider`; otherwise, `null` is returned. In the above code, `part` is a wrapper for `getStatePart`, and `get` is a wrapper for `getState`.

The `Part` type implemented by `MvcController` is `MvcControllerPart`. To create and use `MvcControllerPart`, please read [MvcControllerPart](#mvccontrollerpart).

### Model State

In the controller, you can directly use the `model` property to obtain the model. The model is a state with null key and generic type `TModelType`. You can also obtain it using the method for obtaining state. The model state will be updated when the outside `Mvc` recreates.

To get the model state:

```dart
var model = getState<TModelType>();
```

If there are UI components in a View that depend on updates from an external Model, you can update the UI by getting the state of the Model:

```dart
MvcStateScope<IndexPageController>(
    (MvcWidgetStateProvider state) {
        return Text("${state.get<TModelType>()}");
    },
)
```

If there are logic dependencies on external Model updates in a Controller, you can listen to the Model state:

```dart
getStateValue<TModelType>()?.addListener(() {});
```

## Dependency Injection

Dependency injection is implemented using [https://github.com/yiiim/dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection).

It is recommended to read the [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection) documentation before reading the following.

### MvcDependencyProvider

Use ```MvcDependencyProvider``` to inject dependencies into child elements:

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

```addSingleton``` means injecting a singleton. When all child elements get a dependency of this type, they share the same instance.

```addScopedSingleton``` means injecting a scoped singleton. In Mvc, each Mvc has its own scoped service. When different instances of the Controller retrieve this type of dependency, they obtain different instances, but the same instance within one instance of the Controller.

```add``` injects a normal service. Each time it is retrieved, a new instance is created.

You can also inject ```MvcController```. After injecting the ```MvcController```, you don't need to pass the ```create``` parameter when using ```Mvc```. The ```Mvc``` will create the Controller from the dependency injection.

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addController<IndexPageController>((provider) => IndexPageController());
  },
  child: Mvc<IndexPageController,IndexPageModel>(model: IndexPageModel()),
);
```

### Retrieving Dependencies

Any service created using dependency injection can be included in ```DependencyInjectionService``` to retrieve other injected services. This can also be done in MvcController. The method for retrieving services is defined as follows:

```dart
T getService<T extends Object>();
```

The generic type must match the type used when injecting the service.

### Service Scopes

Each MvcController generates a service scope **using the parent MvcController scope** when it is created. If there is no parent, ```MvcOwner``` is used. By default, the types of singleton services ```MvcController```, ```MvcContext```, and ```MvcView``` are registered in the service scope where the Controller resides. ```MvcController``` represents the Controller itself, ```MvcContext``` represents the Element where the Controller resides, and ```MvcView``` is created by the Controller. The service scope is released when the Controller is destroyed.

## buildScopedService

```dart
@override
void buildScopedService(ServiceCollection collection) {
    collection.add<Object>((serviceProvider) => Object());
}
```

Overriding the ```buildScopedService``` method in the Controller can inject additional services into the service scope generated when the Controller is created. Since the service scope is based on the parent, these additional services can be retrieved by child elements.

For more information on dependency injection, please refer to the [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection) documentation.