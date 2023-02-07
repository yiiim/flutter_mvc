import 'package:example/src/scaffold/view.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ScaffoldController extends MvcController<ScaffoldModel> {
  @override
  MvcView view() {
    return ScaffoldView();
  }

  void updateTitle(String title) {}
}
