import 'package:example/common/toast/controller.dart';
import 'package:example/controller/product.dart';
import 'package:example/controller/shopping_cart.dart';
import 'package:example/pages/index/controller.dart';
import 'package:example/pages/index/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'common/navigator/controller.dart';
import 'src/test_object.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MvcDependencyProvider(
      provider: (collection) {
        collection.addController<IndexPageController>((serviceProvider) => IndexPageController());
        collection.addSingleton((serviceProvider) => TestObject());
        collection.addScopedSingleton((serviceProvider) => TestObject());
        collection.add((serviceProvider) => TestObject());
      },
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MvcProxy(
          proxyCreate: () => NavigatorController(),
          child: Mvc<IndexPageController, IndexPageModel>(
            model: IndexPageModel(title: "Flutter Demo"),
          ),
        ),
        builder: (context, child) {
          return Mvc(
            create: () => ToastController(),
            model: ToastModel(
              MvcMultiProxy(
                proxyCreate: [
                  () => ProductController(),
                  () => ShoppingCartController(),
                ],
                child: child!,
              ),
            ),
          );
        },
      ),
    );
  }
}
