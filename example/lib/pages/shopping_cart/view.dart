import 'package:example/src/models/shopping_cart_product.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'controller.dart';

class ShoppingCartPage extends MvcModelessView<ShoppingCartPageController> {
  @override
  Widget buildView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("购物车"),
      ),
      body: MvcStateScope<ShoppingCartPageController>(
        (state) {
          var datas = state.get<List<ShoppingCartProductModel>>() ?? <ShoppingCartProductModel>[];
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(datas[index].product.title),
                trailing: CupertinoButton(
                  child: const Icon(Icons.delete),
                  onPressed: () => controller.tapDelete(datas[index].product),
                ),
              );
            },
            itemCount: datas.length,
          );
        },
      ),
    );
  }
}
