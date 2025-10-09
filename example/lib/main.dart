import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'dependency_group_example.dart';

void main() {
  runApp(
    MvcApp(
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
class TestService with DependencyInjectionService, MvcDependableObject {
  String title = "Default Title";

  void changeTitle() {
    title = "Service Changed Title";
    notifyAllDependents();
  }

  void update() {
    notifyAllDependents();
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
    querySelectorAll(".timerCount").update(() => timerCount++);
  }

  /// click the FloatingActionButton
  void tapAdd() {
    count++;
    // update the widget with id "count"
    querySelectorAll("#count").update();
  }

  /// click the "update title by controller"
  void changeTestServiceTitle() {
    // get TestService and set title
    getService<TestService>().title = "Controller Changed Title";
    // update The TestService, will be update all MvcServiceScope<TestService>
    getService<TestService>().update();
  }
}

class CounterState {
  CounterState(this.count, [this.count1 = 0]);
  int count;
  int count1;
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
          Builder(
            builder: (context) {
              return Text(
                context.stateAccessor.useState(
                  (CounterState state) => "useState count: ${state.count}",
                  initializer: () => CounterState(0),
                ),
              );
            },
          ),
          MvcServiceScope<TestService>(
            builder: (context, service) {
              return Text(service.title);
            },
          ),
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
                  MvcBuilder(
                    classes: const ["timerCount"],
                    builder: (context) {
                      return Text(
                        '${controller.timerCount}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                  MvcBuilder(
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
                    onPressed: () => controller.querySelectorAll<MvcHeader>().update(),
                    child: const Text("update header"),
                  ),
                  CupertinoButton(
                    onPressed: () => controller.querySelectorAll<MvcFooter>().update(),
                    child: const Text("update footer"),
                  ),
                  CupertinoButton(
                    onPressed: () => controller.widgetScope.setState<CounterState>((state) {
                      state.count++;
                    }),
                    child: const Text("update counter"),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(controller.context).push(
                      MaterialPageRoute(
                        builder: (context) => const DependencyGroupExamplePage(),
                      ),
                    ),
                    child: const Text("依赖分组示例"),
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
