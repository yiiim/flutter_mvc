import 'package:example/pages/detail/controller.dart';
import 'package:example/src/scaffold/controller.dart';
import 'package:example/src/scaffold/view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class DetailPageModel {
  DetailPageModel(this.text, this.index);
  final String text;
  final int index;
}

class DetailPage extends MvcView<DetailPageController, DetailPageModel> {
  @override
  Widget buildView(ctx) {
    return Mvc(
      creater: () => ScaffoldController(),
      model: ScaffoldModel(
        body: Column(
          children: [
            Text("${ctx.model.index}"),
            CupertinoButton(
              onPressed: ctx.controller.updateIndex,
              child: const Text("update index"),
            ),
            CupertinoButton(
              onPressed: ctx.controller.tapPush,
              child: const Text("push"),
            ),
            CupertinoButton(
              onPressed: ctx.controller.tapReplace,
              child: const Text("Replace"),
            ),
          ],
        ),
      ),
    );
  }
}
