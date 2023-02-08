import 'package:example/pages/detail/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class DetailPageController extends MvcController {
  @override
  MvcView view(context) => DetailPage();

  void updateIndex() {
    var p = previousSibling<DetailPageController>();
    p?.updateState<String?>(updater: (state) => state?.value = "detail");
  }

  void tapPush() {
    Navigator.of(context.buildContext).push(
      MaterialPageRoute(
        builder: (context) => Mvc(creater: () => DetailPageController()),
      ),
    );
  }

  void tapReplace() {
    Navigator.of(context.buildContext).replace(
      oldRoute: ModalRoute.of(previousSibling<DetailPageController>()!.previousSibling<DetailPageController>()!.context.buildContext)!,
      newRoute: MaterialPageRoute(
        builder: (context) => Mvc(creater: () => DetailPageController()),
      ),
    );
  }
}
