import 'package:example/src/models/product.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ShoppingCartControllerStateKeys {
  static String shoppingCartProducts = "shoppingCartProducts";
}

class ShoppingCartController extends MvcProxyController {
  @override
  void init() {
    super.init();
    initState<List<ProductModel>>([], key: ShoppingCartControllerStateKeys.shoppingCartProducts);
  }

  void addProduct(ProductModel product) => updateState<List<ProductModel>>(updater: (state) => state?.value.add(product), key: ShoppingCartControllerStateKeys.shoppingCartProducts);
  void removeProduct(String productId) => updateState<List<ProductModel>>(updater: (state) => state?.value.removeWhere((e) => e.id == productId), key: ShoppingCartControllerStateKeys.shoppingCartProducts);
}
