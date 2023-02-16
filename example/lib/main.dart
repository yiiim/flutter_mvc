import 'package:example/common/toast/controller.dart';
import 'package:example/controller/product.dart';
import 'package:example/controller/shopping_cart.dart';
import 'package:example/pages/index/controller.dart';
import 'package:example/pages/index/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'common/navigator/controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MvcProxy(
        proxyCreater: () => NavigatorController(),
        child: Mvc<IndexPageController, IndexPageModel>(
          creater: () => IndexPageController(),
          model: IndexPageModel(title: "Flutter Demo"),
        ),
      ),
      builder: (context, child) {
        return Mvc(
          creater: () => ToastController(),
          model: ToastModel(
            MvcMultiProxy(
              proxyCreater: [
                () => ProductController(),
                () => ShoppingCartController(),
              ],
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
