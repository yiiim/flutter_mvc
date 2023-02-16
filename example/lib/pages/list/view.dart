import 'package:example/controller/shopping_cart.dart';
import 'package:example/pages/list/controller.dart';
import 'package:example/src/models/product.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class ListPage extends MvcModelessView<ListPageController> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List"),
      ),
      body: MvcStateScope<ListPageController>(
        (state) {
          var datas = state.get<List<ProductModel>>() ?? <ProductModel>[];
          var shoppingCartDatas = state.get<List<ProductModel>>(key: ShoppingCartControllerStateKeys.shoppingCartProducts) ?? <ProductModel>[];
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(datas[index].title),
                trailing: shoppingCartDatas.any((element) => element.id == datas[index].id)
                    ? const Text("已添加购物车", style: TextStyle(color: Colors.grey))
                    : CupertinoButton(
                        child: const Icon(Icons.add_shopping_cart_outlined),
                        onPressed: () => ctx.controller.addShoppingCart(datas[index]),
                      ),
              );
            },
            itemCount: datas.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctx.controller.tapShoppingCart,
        child: MvcStateScope(
          (state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                Text(
                  state.get<List<ProductModel>>(key: ShoppingCartControllerStateKeys.shoppingCartProducts)!.length.toString(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
