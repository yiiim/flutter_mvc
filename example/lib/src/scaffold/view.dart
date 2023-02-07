import 'package:example/src/scaffold/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ScaffoldModel {
  ScaffoldModel({
    required this.body,
    this.title,
  });
  final Widget body;
  final String? title;
}

class ScaffoldView extends MvcView<ScaffoldController, ScaffoldModel> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ctx.model.title ?? "test"),
      ),
      body: ctx.model.body,
    );
  }
}
