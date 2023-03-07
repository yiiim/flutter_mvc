import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'view.dart';

class ToastModel {
  ToastModel(this.child);
  final Widget child;
}

class ToastController extends MvcController<ToastModel> with MvcSingleTickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 222));

  @override
  void init() {
    super.init();
    initState<String>("");
  }

  void showToast(String msg) {
    updateState<String>(updater: (state) => state.value = msg);
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        animationController.forward();
        Future.delayed(const Duration(milliseconds: 1500), () {
          animationController.reverse();
        });
      },
    );
  }

  @override
  MvcView view(model) => ToastView();
}
