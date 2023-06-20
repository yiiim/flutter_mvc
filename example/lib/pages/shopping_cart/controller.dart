import 'package:example/common/toast/controller.dart';
import 'package:example/controller/shopping_cart.dart';
import 'package:example/src/models/product.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'view.dart';

class ShoppingCartPageController extends MvcController {
  @override
  MvcView view() => ShoppingCartPage();

  void tapDelete(ProductModel product) {
    Mvc.get<ShoppingCartController>()?.removeProduct(product.id);
    Mvc.get<ToastController>()?.showToast("删除成功");
  }
}
