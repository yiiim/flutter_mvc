import 'package:example/src/models/product.dart';
import 'package:example/src/models/shopping_cart_product.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ShoppingCartController extends MvcProxyController {
  @override
  void init() {
    super.init();
    initState<List<ShoppingCartProductModel>>([]);
  }

  void addProduct(ProductModel product) {
    updateState<List<ShoppingCartProductModel>>(
      updater: (state) => state.value.add(ShoppingCartProductModel(product)),
    );
  }

  void removeProduct(String productId) {
    updateState<List<ShoppingCartProductModel>>(
      updater: (state) => state.value.removeWhere((e) => e.product.id == productId),
    );
  }
}
