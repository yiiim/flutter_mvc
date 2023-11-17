# Flutter Mvc

Flutter framework based on dependency injection, Which can be used for state management.

## Getting Started

```dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  ServiceCollection collection = ServiceCollection();
  collection.addSingleton<TestService>((_) => TestService());
  runApp(
    MvcApp(
      owner: MvcOwner(serviceProvider: collection.build()),
      child: MvcDependencyProvider(
        provider: (collection) {
          collection.addSingleton<TestService>((_) => TestService());
        },
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Mvc(
        create: () => TestMvcController(),
        model: const TestModel("Flutter Mvc Demo"),
      ),
    );
  }
}

/// The dependency injection service
class TestService with DependencyInjectionService, MvcService {
  String title = "Default Title";

  void changeTitle() {
    title = "Service Changed Title";
    update();
  }
}

/// The Model
class TestModel {
  const TestModel(this.title);
  final String title;
}

/// The Controller
class TestMvcController extends MvcController<TestModel> {
  int count = 0;
  int timerCount = 0;
  late Timer timer;

  @override
  void init() {
    super.init();
    timer = Timer.periodic(const Duration(seconds: 1), timerCallback);
  }

  @override
  MvcView view() => TestMvcView();

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  /// timer callback
  void timerCallback(Timer timer) {
    // update the widget with classes "timerCount"
    $(".timerCount").update(() => timerCount++);
  }

  /// click the FloatingActionButton
  void tapAdd() {
    count++;
    // update the widget with id "count"
    $("#count").update();
  }

  /// click the "update title by controller"
  void changeTestServiceTitle() {
    // get TestService and set title
    getService<TestService>().title = "Controller Changed Title";
    // update The TestService, will be update all MvcServiceScope<TestService>
    updateService<TestService>();
  }
}

/// The View
class TestMvcView extends MvcView<TestMvcController> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(controller.model.title),
      ),
      body: Column(
        children: [
          MvcHeader(
            builder: (context) {
              return Container(
                height: 44,
                color: Color(
                  Random().nextInt(0xffffffff),
                ),
              );
            },
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MvcServiceScope<TestService>(
                    builder: (context, service) {
                      return Text(service.title);
                    },
                  ),
                  MvcBuilder<TestMvcController>(
                    classes: const ["timerCount"],
                    builder: (context) {
                      return Text(
                        '${controller.timerCount}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  MvcBuilder<TestMvcController>(
                    id: "count",
                    builder: (context) {
                      return Text(
                        '${controller.count}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  CupertinoButton(
                    onPressed: controller.changeTestServiceTitle,
                    child: const Text("update title by controller"),
                  ),
                  CupertinoButton(
                    onPressed: () => getService<TestService>().changeTitle(),
                    child: const Text("update title by self service"),
                  ),
                  CupertinoButton(
                    onPressed: () => controller.$<MvcHeader>().update(),
                    child: const Text("update header"),
                  ),
                  CupertinoButton(
                    onPressed: () => controller.$<MvcFooter>().update(),
                    child: const Text("update footer"),
                  ),
                ],
              ),
            ),
          ),
          MvcFooter(
            builder: (context) {
              return Container(
                height: 44,
                color: Color(
                  Random().nextInt(0xffffffff),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapAdd,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

```

## Use Mvc

Create Controller

```dart
class TestMvcController extends MvcController<TestModel> {
  @override
  void init() {
    super.init();
  }
}
```

Create Model

```dart
class TestModel {
  const TestModel(this.title);
  final String title;
}
```

Create View

```dart
class TestMvcView extends MvcView<TestMvcController, TestModel> {
  @override
  Widget buildView() {
    return Text(model.title);
  }
}
```

Use Mvc in Flutter

```dart
Mvc(
  create: () => TestMvcController(),
  model: const TestModel("Flutter Mvc Demo"),
)
```

The only thing you need to pay attention to is that `Mvc` must have an `MvcApp` as its parent.

## Dependency Injection

Dependency injection is provided by [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection).

### Get the objects you've injected

There are many ways to get the objects you've injected.

Use `getService` in `MvcController`, `MvcWidgetState`, `MvcView` to get them.

```dart
// In MvcController
class TestMvcController extends MvcController<TestModel> {
  @override
  void init() {
    super.init();
    final testService = getService<TestService>();
  }
}

// In MvcWidgetState
class TestMvcStatefulWidget extends MvcStatefulWidget {
  MvcWidgetState createState() => TestMvcStatefulState();
}
class TestMvcStatefulState extends MvcWidgetState {
  @override
  void init() {
    super.init();
    final testService = getService<TestService>();
  }
}

// In MvcView
class TestMvcView extends MvcView<TestMvcController, TestModel> {
  @override
  Widget buildView() {
    final testService = getService<TestService>();
    return Text(testService.title);
  }
}
```

Use the `MvcServiceScope` widget to get them.

```dart
Widget build(BuildContext context) {
  return MvcServiceScope<TestService>(
    builder: (context, service) {
      return Text(service.title);
    },
  );
}
```

Use `BuildContext` to get them.

```dart
Widget build(BuildContext context) {
  final testService = context.getService<TestService>();
  return Text(testService.title);
}
```

### Inject objects

Create initial dependency injection objects in `MvcApp`.

```dart
var collection = ServiceCollection();
collection.addSingleton<TestService>((_) => TestService());
var serviceProvider = collection.build();
MvcApp(
  owner: MvcOwner(serviceProvider: serviceProvider),
  child: MyApp(),
)
```

Use `MvcDependencyProvider` to inject to children.

```dart
MvcDependencyProvider(
    provider: (collection) {
      collection.addSingleton<TestService>((_) => TestService());
    },
    child: const MyApp(),
)
```

Use `MvcController` to inject to children.

```dart
class TestMvcController extends MvcController<TestModel> {
  @override
  void initServices(ServiceCollection collection, ServiceProvider parent) {
    super.initServices(collection, parent);
    collection.addSingleton<TestService>((_) => TestService());
  }
}
```

Use `MvcStatefulWidget` to inject to children.

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

In Mvc, children can get all objects injected by their parents. If a child injects the same object, the child's object will override the parent's object.

## State Management

### Update Widget using id, classes, WidgetType

```dart
class MyWidget extends MvcStatelessWidget {
  const MyWidget({super.key, super.id, super.classes});
  @override
  Widget build(BuildContext context) {
    return Text('${context.getService<TestMvcController>().count}');
  }
}
class TestMvcController extends MvcController<TestModel> {
  int count = 0;
  @override
  MvcView view() => TestMvcView();
  void tapAdd() {
    $("#count").update(() => count++); // update the widget with id "count"
    $(".count").update(() => count++); // update the widget with classes "count"
    $<MyWidget>().update(() => count++); // update the widget with WidgetType MyWidget
  }
}
class TestMvcView extends MvcView<TestMvcController, TestModel> {
  @override
  Widget buildView() {
    return Column(
      children: [
        MyWidget<TestMvcController>(
          id: "count",
          classes: const ["count"],
        ),
      ],
    );
  }
}
```

### Make Widget depend on injected objects

#### Use `MvcServiceScope` Widget

```dart
class TestMvcView extends MvcView<TestMvcController, TestModel> {
  @override
  Widget buildView() {
    return MvcServiceScope<TestService>(
      builder: (context, service) {
        return Text('${service.count}');
      },
    );
  }
}
```

#### Use `MvcContext` to depend on objects

```dart
class TestMvcView extends MvcView<TestMvcController, TestModel> {
  @override
  Widget buildView() {
    final testService = context.getService<TestService>();
    return MvcBuilder(
      builder: (context) {
        return Text('${context.dependOnService<TestService>().count}');
      }
    );
  }
}
```

#### Update Widget that depends on objects

Use mixin: `MvcService` to update within the object

```dart
class TestService with DependencyInjectionService, MvcService {
  int count = 0;
  void changeTitle() {
    update(()=>count++);
  }
}
```

Update in MvcController

```dart
class TestMvcController extends MvcController<TestModel> {
  void changeTitle() {
    updateService<TestService>((service) => service.count++);
  }
}
```
