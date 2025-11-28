import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:todos/home/controller.dart';

void main() {
  runApp(
    const MvcApp(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Mvc(
        create: () => HomeController(),
      ),
    );
  }
}
