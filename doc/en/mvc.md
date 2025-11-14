# MVC Core Components

The core of the `flutter_mvc` framework is the `Mvc` widget, which organically combines the Model, View, and Controller.

## 1. `Mvc` Widget

The `Mvc` widget acts as the bridge between the Controller and the View. It is responsible for creating and managing the Controller's lifecycle and building and updating the View based on the Controller's instructions.

**Basic Usage:**

```dart
void main() {
  runApp(
    MaterialApp(
      home: MvcApp( // MvcApp is the root of all flutter_mvc applications
        child: Mvc(
          create: () => IndexController(), // Provide a factory to create the Controller
        ),
      ),
    ),
  );
}
```

- `create`: A function that returns an `MvcController` instance. This is required unless you provide the Controller in a parent scope using the `addController` method based on [dependency injection](./dependency_injection.md).

## 2. Controller

The Controller is the core of your business logic. It handles user input, manages state, interacts with the data model, and decides when to update the View.

**Controller Example:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class IndexController extends MvcController {
  // Override the view method to return an MvcView instance
  @override
  MvcView<IndexController> view() => IndexPageView();

  int _counter = 0;
  int get counter => _counter;

  // Business logic method
  void increment() {
    _counter++;
    // Notify the View to rebuild
    update();
  }

  // --- Lifecycle Methods ---

  @override
  void init() {
    super.init();
    // Called when the Controller is initialized, suitable for one-time setup
  }

  @override
  void didUpdateModel(TModelType oldModel) {
    super.didUpdateModel(oldModel);
    // Called when the model is updated, suitable for handling model changes
  }
}
```

- **`view()`**: You must implement this method to return an `MvcView` instance.
- **`update()`**: Calling this method triggers the `buildView` method of the `MvcView`, thereby rebuilding the entire View. For more granular control, you can use [selectors](./selector.md) or the [Store](./store.md) for partial updates.

## 3. View

The View is responsible for UI presentation. It is a pure UI layer, solely responsible for building widgets based on the state provided by the Controller.

**View Example:**

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        // Access model data through the controller
        title: Text("MVC Demo"),
      ),
      body: Center(
        child: Text(
          '${controller.counter}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // Call the controller's method to handle user interaction
        onPressed: () => controller.increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- **Generics**: The `TControllerType` in `MvcView<TControllerType>` is the type of its associated Controller.
- **`buildView()`**: You must implement this method to return a Widget. This is where you build the view's UI.
- **`controller`**: You can safely access the associated Controller instance through the `controller` property to get data or call its methods.
- **`context`**: You can get the `BuildContext` through the `context` property.

## `Mvc` and Dependency Injection

Both `MvcController` and `MvcView` are integrated into the dependency injection system.

- `MvcController` is registered as a **singleton** within its scope.
- `MvcView` is registered as **transient** within its scope.

This means you can use `getService<T>()` inside the Controller and View to retrieve any other registered services, achieving a clear separation of concerns.

**Example: Using a Service in a Controller**

```dart
class IndexController extends MvcController {
  void performAction() {
    // Assuming AuthService has been registered
    final authService = getService<AuthService>();
    authService.login();
  }

  @override
  MvcView<IndexController> view() => IndexPageView();
}
```

**Example: Using a Service in a View**

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    // Assuming SettingsService has been registered
    final settings = getService<SettingsService>();

    return Scaffold(
      backgroundColor: settings.isDarkMode ? Colors.black : Colors.white,
      // ...
    );
  }
}
```
