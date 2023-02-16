import 'package:example/common/navigator/controller.dart';
import 'package:example/common/toast/controller.dart';
import 'package:example/controller/shopping_cart.dart';
import 'package:example/pages/list/view.dart';
import 'package:example/pages/shopping_cart/controller.dart';
import 'package:example/src/models/product.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ListPageController extends MvcController {
  @override
  MvcView<MvcController, dynamic> view(context) => ListPage();

  void addShoppingCart(ProductModel product) {
    Mvc.get<ShoppingCartController>()?.addProduct(product);
    Mvc.get<ToastController>()?.showToast("添加成功");
  }

  void tapShoppingCart() {
    Mvc.get<NavigatorController>()?.pushViewController(() => ShoppingCartPageController());
  }
}
