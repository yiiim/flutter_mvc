import 'package:flutter_mvc/flutter_mvc.dart';

import 'view.dart';

class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0);
  }

  void incrementCounter() {
    updateState<int>(updater: ((state) => state?.value++));
    update();
  }

  @override
  MvcView view() {
    return IndexPage();
  }
}
