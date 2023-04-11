import 'package:example/pages/list/controller.dart';
import 'package:example/src/test_object.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'view.dart';

class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0);
  }

  void incrementCounter() {
    updateState<int>(updater: ((state) => state.value++));
    update();
  }

  void tapPush() {
    Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (context) {
          return Mvc(create: () => ListPageController());
        },
      ),
    );
  }

  @override
  MvcView view(model) {
    return IndexPage();
  }
}
