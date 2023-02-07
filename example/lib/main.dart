import 'package:example/pages/index/controller.dart';
import 'package:example/pages/index/view.dart';
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
        creater: () => IndexPageController(),
        model: IndexPageModel(title: "Flutter Demo"),
      ),
    );
  }
}
