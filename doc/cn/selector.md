# 选择器

`flutter_mvc` 提供了一套强大的选择器 API，其设计灵感来源于 Web 开发中的 CSS 选择器。这使得开发者可以方便地从控件树的任何位置查找和操作其他 `MvcWidget`。

## 核心 API

- `querySelector<T>(String selector)`: 查找满足选择器条件的**第一个** `MvcWidget`。
- `querySelectorAll<T>(String selector)`: 查找满足选择器条件的**所有** `MvcWidget`。

这两个方法都可以在 `MvcController`、`MvcWidgetState` 或 `MvcWidgetScope` 中调用。

## 支持的选择器语法

### 1. ID 选择器 (`#`)

通过为 `MvcWidget` 设置 `id` 属性，你可以使用 ID 选择器来精确查找。

**示例**:

```dart
String text = "Initial Text";
// 定义如下 Widget
class MyWidget extends MvcStatelessWidget {
  const MyWidget({super.key, super.id, super.classes, super.attributes});
  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

// 在 View 中使用 Widget
MyWidget(id: 'my-unique-id');

// 在 Controller 或父控件中查找
final widgetScope = querySelector<MyWidget>('#my-unique-id');
widgetScope?.update(); // 如果找到了，就重建它
```

### 2. Class 选择器 (`.`)

通过为 `MvcWidget` 设置 `classes` 属性（可以是一个或多个类，用空格分隔），你可以使用类选择器来查找一组控件。

**示例**:

```dart
// 定义带 class 的控件
MyWidget(classes: ['card', 'highlight']);
MyWidget(classes: ['card']);

// 查找所有带 'highlight' 类的 MyWidget
final scopes = querySelectorAll<MyWidget>('.highlight');
// 重建所有找到的控件
for (final scope in scopes) {
  scope.update();
}
```

### 3. 属性选择器 (`[]`)

你可以根据 `MvcWidget` 的任意公开属性来进行查找。

**支持的匹配方式**:

- `[attr]`: 属性存在。
- `[attr=value]`: 属性值完全匹配。
- `[attr^=value]`: 属性值以前缀 `value` 开头。
- `[attr$=value]`: 属性值以后缀 `value` 结尾。
- `[attr*=value]`: 属性值包含 `value`。
- `[attr~=value]`: 属性值是一个以空格分隔的列表，其中包含 `value`。

**示例**:

```dart
// 使用上面定义的 MyWidget
MyWidget(attributes: {"key": "value"},);

// 查找所有`attributes` 'key' 为 'value' 的控件
final activeWidgets = querySelectorAll<MyWidget>('[key=value]');
```

### 4. 组合选择器

你可以将上述选择器组合起来，以实现更复杂的查询。

- **后代选择器 (空格)**: `A B` - 查找 `A` 控件的所有后代中满足 `B` 条件的控件。
- **子代选择器 (`>`)**: `A > B` - 查找 `A` 控件的直接子代中满足 `B` 条件的控件。

**示例**:

```dart
// 查找 id 为 'container' 的控件下，所有 class 为 'item' 的直接子代
final items = querySelectorAll('#container > .item');
```

## 注意事项

- **性能**: 选择器查询虽然经过优化，但仍有一定开销。避免在性能敏感的代码路径（如 `build` 方法中）或高频调用的地方滥用。
- **可查找对象**: 只有继承自 `MvcWidget` 的 Widget 才能被选择器系统识别和查找。
- **查询方向**: 选择器只能向下（后代）或向内查找，**不支持查找兄弟或祖先节点**。
- **规范**: 确保你的选择器字符串符合 CSS 选择器规范。
