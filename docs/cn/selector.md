# Css 选择器

`flutter_mvc` 支持类似 Web 的 Css 选择器来定位 Widget。您可以通过 ID、Class 甚至是 Widget 类型来精确定位/更新 Widget。

## 快速开始

下面是一个简单的计数器示例，展示了如何使用 Selector 来更新 Widget。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
int count = 0;
void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: MvcBuilder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: MvcBody(
                  id: "counterText",
                  classes: ["counter"],
                  attributes: {"data-test": "123"},
                  builder: (context) {
                    return Text(
                      '$count',
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  count++;
                  context.querySelector("#counterText")?.update();
                  // or
                  context.querySelector(".counter")?.update();
                  // or
                  context.querySelector("[data-test='123']")?.update();
                  // or
                  context.querySelector<MvcBody>()?.update();
                },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            );
          },
        ),
      ),
    ),
  );
}
```

`MvcWidget` 提供了 `id`、`classes` 和 `attributes` 属性来设置选择器信息。您可以通过 `MvcContext` 的方法 `querySelector` 来查找 Widget，并调用 `update()` 方法来更新它。您无法直接通过`BuildContext`来查找 Widget，必须通过 `MvcContext`。幸运的是你可以通过 `BuildContext` 通过依赖注入的方式 `getMvcService<MvcContext>()` 获取 `MvcContext`。通过`MvcContext`查询时只会查找其子级，所以你必须确保你要查找的 Widget 是 `MvcContext` 的子级。另外你可以通过静态方法 `Mvc.querySelector` 从根开始查找 Widget。

* 你只能查找到 `MvcWidget`以及其子类，不能查找到普通的 Widget。
* 无法查找兄弟节点
* 请确保你的选择器信息符合 Css 选择器规范。
* 选择器查找虽然不会遍历全部 `Widget`树，但会遍历`MvcWidget`，有一定的性能开销，不要在性能敏感的地方频繁调用。