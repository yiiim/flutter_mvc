import 'package:example/src/models/product.dart';

class ShoppingCartProductModel {
  ShoppingCartProductModel(this.product, {DateTime? addDate}) : addDate = addDate ?? DateTime.now();
  ProductModel product;
  DateTime addDate;
}
