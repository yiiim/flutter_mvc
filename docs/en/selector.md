# Selector

`flutter_mvc` supports CSS-like selectors to locate Widgets. You can precisely target/update Widgets through ID, Class, or even Widget types.

## Quick Start

Here's a simple counter example that shows how to use Selector to update Widgets.

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

`MvcWidget` provides `id`, `classes`, and `attributes` properties to set selector information. You can use the `querySelector` method of `MvcContext` to find Widgets and call the `update()` method to update them. You cannot directly find Widgets through `BuildContext`; you must go through `MvcContext`. Fortunately, you can get `MvcContext` through dependency injection via `BuildContext` using `getMvcService<MvcContext>()`. When querying through `MvcContext`, it will only search its children, so you must ensure that the Widget you're looking for is a child of `MvcContext`. Additionally, you can use the static method `Mvc.querySelector` to search for Widgets starting from the root.

* You can only find `MvcWidget` and its subclasses, not regular Widgets.
* Cannot find sibling nodes
* Please ensure your selector information conforms to CSS selector specifications.
* Although selector search doesn't traverse the entire `Widget` tree, it does traverse `MvcWidget`s, which has some performance overhead. Don't call it frequently in performance-sensitive places.