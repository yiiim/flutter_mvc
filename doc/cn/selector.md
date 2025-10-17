# 选择器

`flutter_mvc` 引入了一个强大的选择器（Selector）系统，其灵感来源于 Web 的 CSS 选择器。这使你能够通过 ID、类名（Class）、属性（Attribute）甚至是 Widget 类型来精确定位并更新 Widget，从而实现对 UI 的精细化控制，避免不必要的全局刷新。

## 核心概念

任何继承自 `MvcWidget` 的 Widget（例如 `MvcStatelessWidget`, `MvcStatefulWidget`, `Mvc`）都可以被选择器定位。你需要为这些 Widget 提供元数据：

-   **`id`**: 一个唯一的字符串标识符，类似于 HTML 中的 `id`。
-   **`classes`**: 一个字符串列表，类似于 HTML 中的 `class`。一个 Widget 可以有多个类名。
-   **`attributes`**: 一个 `Map<Object, String>`，用于存储自定义属性，类似于 HTML 中的 `data-*` 属性。
-   **类型**: Widget 本身的类型也可以作为选择器的一部分。

## 快速开始

下面是一个简单的计数器示例，展示了如何使用不同的选择器来更新一个 `Text` Widget。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

int count = 0;

void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                // 1. 使用 MvcWidget (这里是 MvcBody) 并设置选择器属性
                child: MvcBody(
                  id: "counter-text",
                  classes: ["counter", "display"],
                  attributes: {"data-value": "count"},
                  builder: (widgetScope) {
                    return Text(
                      '$count',
                      style: Theme.of(widgetScope.context).textTheme.headlineMedium,
                    );
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  count++;
                  
                  // 2. 使用选择器查找并更新 Widget
                  // 你可以在 MvcController, MvcWidgetState, 或任何能访问到 MvcWidgetScope 的地方调用
                  
                  // 按 ID 查找
                  Mvc.querySelector("#counter-text")?.update();
                  
                  // 按 Class 查找 (返回第一个匹配项)
                  // Mvc.querySelector(".counter")?.update();
                  
                  // 按属性查找
                  // Mvc.querySelector("[data-value='count']")?.update();
                  
                  // 按类型查找 (会找到第一个 MvcBody)
                  // Mvc.querySelector<MvcBody>()?.update();

                  // 组合查找
                  // Mvc.querySelector<MvcBody>(".display")?.update();
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

## 如何查询

### 查询 API

-   `querySelector<T>(selectors)`: 查找**第一个**匹配选择器条件的后代 Widget。
-   `querySelectorAll<T>(selectors)`: 查找**所有**匹配选择器条件的后代 Widget，返回一个可迭代的集合。

### 查询起点

你可以从不同的“起点”开始查询：

1.  **全局查询 (`Mvc.querySelector`)**:
    从应用的根部开始查找整个 Widget 树。这是最简单直接的方式。

    ```dart
    Mvc.querySelector("#my-widget")?.update();
    ```

2.  **从特定范围查询 (`widgetScope.querySelector`)**:
    在 `MvcController`、`MvcWidgetState` 或 `MvcWidgetScopeBuilder` 中，你可以通过 `widgetScope` 属性从当前 Widget 的位置开始向下查找。这有助于限定查询范围，提高效率和准确性。

    ```dart
    // 在一个 Controller 中
    class MyController extends MvcController {
      void refreshList() {
        // 只查找当前 Controller 管辖范围内的 '.list-item'
        widgetScope.querySelectorAll('.list-item').update();
      }
      // ...
    }
    ```

### 选择器语法

支持常见的 CSS 选择器语法：

-   **ID 选择器**: `#my-id`
-   **类选择器**: `.my-class`
-   **属性选择器**: `[data-value='abc']`, `[data-active]`
-   **类型选择器**: `MyCustomWidget` (通过泛型 `<T>` 指定)
-   **后代选择器**: `MyContainer .my-item` (查找 `MyContainer` 下的所有 `.my-item`)
-   **子代选择器**: `MyList > .list-item` (只查找 `MyList` 的直接子元素 `.list-item`)

## `isSelectorBreaker`

有时，你可能希望某个组件成为一个“黑盒”，阻止外部的选择器查询进入其内部。例如，一个可复用的第三方库组件。

你可以通过在 `MvcController` 或 `MvcWidgetState` 中重写 `isSelectorBreaker` 并返回 `true` 来实现这一点。

```dart
class MyPrivateComponentController extends MvcController {
  @override
  bool get isSelectorBreaker => true; // 外部查询到此为止
  // ...
}
```

当选择器查询遇到一个 `isSelectorBreaker` 为 `true` 的 Widget 时，它将不会继续搜索该 Widget 的子树，除非在查询时明确设置 `ignoreSelectorBreaker: true`。

## 注意事项

-   **性能**: 选择器查询虽然经过优化，但仍有一定开销。避免在性能敏感的代码路径（如 `build` 方法中）或高频调用的地方滥用。
-   **可查找对象**: 只有继承自 `MvcWidget` 的 Widget 才能被选择器系统识别和查找。
-   **查询方向**: 选择器只能向下（后代）或向内查找，不支持查找兄弟或祖先节点。
-   **规范**: 确保你的选择器字符串符合 CSS 选择器规范。