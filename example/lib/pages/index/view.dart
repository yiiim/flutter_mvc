import 'package:example/pages/index/controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class IndexPageModel {
  IndexPageModel({required this.title});
  final String title;
}

class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(model.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            MvcStateScope<IndexPageController>(
              (MvcStateContext state) {
                return Builder(
                  builder: (context) {
                    return Text("${state.get<int>()}");
                  },
                );
              },
            ),
            CupertinoButton(onPressed: controller.tapPush, child: const Text("start demo")),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
