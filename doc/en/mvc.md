## MVC

### Using Mvc

```dart
void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: Mvc(
          create: () => IndexController(),
          model: IndexPageModel(),
        ),
      ),
    ),
  );
}
```

The Model is optional. If you don't need to pass data from external sources, it can usually be omitted.

### Controller Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class IndexPageModel {
  IndexPageModel();
  // **
}

class IndexController extends MvcController<IndexPageModel> {
  @override
  void init() {
    // Initialization code
  }

  @override
  void didUpdateModel(TModelType oldModel) {
    // Called when the Mvc Widget is updated
  }

  @override
  MvcView view() {
    return IndexPageView();
  }
}
```

Controller inherits from `MvcController<TModelType>`, where `TModelType` is the type of the passed Model. If no Model is passed, you can use `MvcController<void>` or simply omit the generic. The `view()` method must be implemented and return an `MvcView` instance. You can rebuild the entire `View` through the `update()` method, or perform partial updates through [selectors](./selectors.md) or [Store](./store.md).

### View Example

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Center(
        child: Text(controller.title),
      ),
    );
  }
}
```

View inherits from `MvcView<TControllerType>`, where `TControllerType` is the associated Controller type. The `buildView()` method must be implemented and return a Widget. You can access the associated Controller instance through the `controller` property and get `BuildContext` through `context`.

## Mvc and Dependency Injection
Both Controller and View are dependency injection objects, and they can both obtain other dependency injection objects through the `getService<T>()` method.

```dart
class IndexController extends MvcController<IndexPageModel> {
  @override
  void clickButton() {
    getService<SomeService>().doSomething();
  }
}
```

```dart
class IndexPageView extends MvcView<IndexController> {
  @override
  Widget buildView() {
    final someValue = getService<SomeService>().someValue;
    return Scaffold(
      body: Center(
        child: Text(someValue),
      ),
    );
  }
}
```