# Selectors

`flutter_mvc` provides a powerful selector API inspired by CSS selectors from web development. This allows developers to easily find and manipulate other `MvcWidget`s from anywhere in the widget tree.

## Core API

- `querySelector<T>(String selector)`: Finds the **first** `MvcWidget` that matches the selector condition.
- `querySelectorAll<T>(String selector)`: Finds **all** `MvcWidget`s that match the selector condition.

Both methods can be called within an `MvcController`, `MvcWidgetState`, or `MvcWidgetScope`.

## Supported Selector Syntax

### 1. ID Selector (`#`)

By setting the `id` property on an `MvcWidget`, you can use the ID selector for precise lookups.

**Example**:

```dart
String text = "Initial Text";
// Define the following Widget
class MyWidget extends MvcStatelessWidget {
  const MyWidget({super.key, super.id, super.classes, super.attributes});
  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

// Use the Widget in the View
MyWidget(id: 'my-unique-id');

// Find it in a Controller or parent widget
final widgetScope = querySelector<MyWidget>('#my-unique-id');
widgetScope?.update(); // If found, rebuild it
```

### 2. Class Selector (`.`)

By setting the `classes` property on an `MvcWidget` (which can be one or more classes separated by spaces), you can use the class selector to find a group of widgets.

**Example**:

```dart
// Define widgets with classes
MyWidget(classes: ['card', 'highlight']);
MyWidget(classes: ['card']);

// Find all MyWidget instances with the 'highlight' class
final scopes = querySelectorAll<MyWidget>('.highlight');
// Rebuild all found widgets
for (final scope in scopes) {
  scope.update();
}
```

### 3. Attribute Selector (`[]`)

You can find widgets based on any of their public attributes.

**Supported matching modes**:

- `[attr]`: Attribute exists.
- `[attr=value]`: Attribute value matches exactly.
- `[attr^=value]`: Attribute value starts with the prefix `value`.
- `[attr$=value]`: Attribute value ends with the suffix `value`.
- `[attr*=value]`: Attribute value contains `value`.
- `[attr~=value]`: Attribute value is a space-separated list that contains `value`.

**Example**:

```dart
// Using the MyWidget defined above
MyWidget(attributes: {"key": "value"});

// Find all widgets where the 'key' attribute is 'value'
final activeWidgets = querySelectorAll<MyWidget>('[key=value]');
```

### 4. Combinators

You can combine the selectors above to perform more complex queries.

- **Descendant Selector (space)**: `A B` - Finds all descendants of widget `A` that match condition `B`.
- **Child Selector (`>`)**: `A > B` - Finds all direct children of widget `A` that match condition `B`.

**Example**:

```dart
// Find all direct children with the class 'item' under the widget with id 'container'
final items = querySelectorAll('#container > .item');
```

## Important Notes

- **Performance**: While selector queries are optimized, they still have some overhead. Avoid overusing them in performance-sensitive code paths (like the `build` method) or high-frequency calls.
- **Queryable Objects**: Only widgets that inherit from `MvcWidget` can be recognized and found by the selector system.
- **Query Direction**: Selectors can only search downwards (descendants) or inwards. **They do not support finding siblings or ancestors.**
- **Specification**: Ensure your selector string conforms to the CSS selector specification.

Next: [`Widget Depends on Object`](depend_on_service.md)
