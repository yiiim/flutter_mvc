import 'package:example/pages/detail/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class DetailPageController extends MvcController<DetailPageModel> {
  @override
  MvcView view() => DetailPage();

  void updateIndex() {
    var p = previousSibling<DetailPageController>();
    p?.updateState<String?>(updater: (state) => state?.value = "detail");
  }

  void tapPush() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Mvc(creater: () => DetailPageController(), model: DetailPageModel("from detail 1", model.index + 1)),
      ),
    );
  }

  void tapReplace() {
    Navigator.of(context).replace(
      oldRoute: ModalRoute.of(previousSibling<DetailPageController>()!.previousSibling<DetailPageController>()!.context)!,
      newRoute: MaterialPageRoute(
        builder: (context) => Mvc(creater: () => DetailPageController(), model: DetailPageModel("from detail 2", 8)),
      ),
    );
  }
}
