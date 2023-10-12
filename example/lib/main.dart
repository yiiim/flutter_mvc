import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(
    MvcApp(
      child: MvcDependencyProvider(
        provider: (collection) {
          // inject service, you can inject any object, then you can get it in controller and view with getService<T> method
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
                    onPressed: () => controller.$<MvcHeader>(),
                    child: const Text("update header"),
                  ),
                  CupertinoButton(
                    onPressed: () => controller.$<MvcFooter>(),
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
