import 'package:example/controller/shopping_cart.dart';
import 'package:example/src/models/product.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'controller.dart';

class ShoppingCartPage extends MvcModelessView<ShoppingCartPageController> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("购物车"),
      ),
      body: MvcStateScope<ShoppingCartPageController>(
        (state) {
          var datas = state.get<List<ProductModel>>(key: ShoppingCartControllerStateKeys.shoppingCartProducts) ?? <ProductModel>[];
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(datas[index].title),
                trailing: CupertinoButton(
                  child: const Icon(Icons.delete),
                  onPressed: () => ctx.controller.tapDelete(datas[index]),
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
