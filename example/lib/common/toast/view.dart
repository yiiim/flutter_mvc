import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'controller.dart';

class ToastView extends MvcView<ToastController, ToastModel> {
  @override
  Widget buildView(ctx) {
    return Material(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: ctx.model.child),
          FadeTransition(
            opacity: ctx.controller.animationController,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx.buildContext).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MvcStateScope<ToastController>(
                  (state) {
                    return Text(
                      state.get<String>() ?? "",
                      style: const TextStyle(color: Colors.white),
                      maxLines: 8,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
