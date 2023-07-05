import 'package:example/src/models/product.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ProductController extends MvcProxyController {
  @override
  void init() {
    super.init();
    
    initState<List<ProductModel>>(
      [
        ProductModel("1", "Product 1"),
        ProductModel("2", "Product 2"),
        ProductModel("3", "Product 3"),
        ProductModel("4", "Product 4"),
        ProductModel("5", "Product 5"),
        ProductModel("6", "Product 6"),
        ProductModel("7", "Product 7"),
        ProductModel("8", "Product 8"),
        ProductModel("9", "Product 9"),
        ProductModel("10", "Product 10"),
        ProductModel("11", "Product 11"),
        ProductModel("12", "Product 12"),
      ],
    );
  }
}
