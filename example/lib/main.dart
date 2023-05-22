import 'package:example/common/toast/controller.dart';
import 'package:example/controller/product.dart';
import 'package:example/controller/shopping_cart.dart';
import 'package:example/pages/index/controller.dart';
import 'package:example/pages/index/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'common/navigator/controller.dart';

class TestModellessController extends MvcController {
  TestModellessController({this.viewBuilder});
  final Widget Function(MvcContext<TestModellessController, void> context)? viewBuilder;
  @override
  MvcView<MvcController, dynamic> view(model) {
    return MvcModelessViewBuilder<TestModellessController>(
      (context) {
        if (viewBuilder != null) return viewBuilder!(context);
        return Text(model.title, textDirection: TextDirection.ltr);
      },
    );
  }

  @override
  void initPart(MvcControllerPartCollection collection) {
    super.initPart(collection);
  }
}

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
      },
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MvcProxy(
          proxyCreate: () => NavigatorController(),
          child: Mvc(
            create: () => IndexPageController(),
            model: IndexPageModel(title: "Mvc Demo"),
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
