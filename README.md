# Flutter Mvc

Flutter framework based on dependency injection, which can be used for state management.

# Getting Started

  
```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(
    MvcDependencyProvider(
      provider: (collection) {
        // inject service, you can inject any object, then you can get it in controller and view with getService<T> method
        collection.addSingleton<TestService>((_) => TestService());
      },
      child: const MyApp(),
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
      home: Mvc(create: () => TestMvcController()),
    );
  }
}

/// The dependency injection service
class TestService extends MvcServiceState {
  String title = "Test Title";

  void updateTitle(String title) {
    this.title = title;

    // call MvcServiceState's update method, update MvcServiceStateScope
    update();
  }
}

/// The Controller
class TestMvcController extends MvcController {
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
    timerCount++;
    // update the widget with classes "timerCount"
    $(".timerCount").update();
  }

  /// click the FloatingActionButton
  void tapAdd() {
    count++;
    // update the widget with id "count"
    $("#count").update();
  }

  /// click the AppBar action button
  void changeTestServiceTitle() {
    // call the service method
    getService<TestService>().updateTitle("TestMvcController Changed Title");
  }
}

/// The View
class TestMvcView extends MvcView<TestMvcController, dynamic> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Test"),
        actions: [
          CupertinoButton(
            onPressed: controller.changeTestServiceTitle,
            child: const Text("update title"),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MvcServiceStateScope<TestService>(
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
          ],
        ),
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