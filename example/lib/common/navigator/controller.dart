import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class NavigatorController extends MvcProxyController {
  void pushViewController<T extends MvcController<E>, E>(T Function() creater, {E? model}) {
    Navigator.of(context.buildContext).push(MaterialPageRoute(builder: (context) => Mvc(creater: creater, model: model)));
  }
}
