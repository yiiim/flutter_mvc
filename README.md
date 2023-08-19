# Flutter Mvc

## Features

Flutter Mvc is a Flutter framework that includes UI and logic separation, state management, and dependency injection.

## Getting started

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(const MyApp());
}

class TestMvcController extends MvcController {
  int count = 0;
  @override
  MvcView view() => TestMvcView();

  void tapAdd() {
    count++;
    $("#test").update();
  }
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

class TestMvcView extends MvcView<TestMvcController, dynamic> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Test"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            MvcBuilder<TestMvcController>(
              classes: const ["test"],
              id: "test",
              builder: (context) {
                return Text(
                  '${context.controller.count}',
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