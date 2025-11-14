````markdown
# Scopes

In `flutter_mvc`, there are two important scope concepts: `MvcWidgetScope` and `MvcStateScope`.

## MvcWidgetScope

Every `MvcWidget` (i.e., `MvcStatelessWidget`, `MvcStatefulWidget`, `Mvc`, etc.) has a corresponding `MvcWidgetScope`, which provides the ability to interact with that specific widget instance.

### Key Functions

1.  **Accessing `BuildContext`**:
    You can get the current widget's `BuildContext` via `widgetScope.context`.

2.  **Widget Querying (`querySelector`, `querySelectorAll`)**:
    This is the core of the `flutter_mvc` selector feature. You can start from any `MvcWidgetScope` and use CSS-like selector syntax to find other `MvcWidgets` in the tree.

    ```dart
    // In a Controller or MvcWidgetState
    // Find all widgets with the class 'highlight' and update them
    widgetScope.querySelectorAll('.highlight').update();
    ```

3.  **Triggering Rebuild (`update`)**:
    Calling the `widgetScope.update()` method marks the current widget as needing a rebuild. This is very useful when you need to precisely control the refresh of a specific `MvcWidget` from an external source.

### How to Obtain It

- In an `MvcController` or `MvcWidgetState`, you can directly access it through the `widgetScope` property.
- By getting an instance of type `MvcWidgetScope` through dependency injection. When using dependency injection, be mindful of the scope rules to ensure you get the instance from the correct scope.

## MvcStateScope

The state scope, `MvcStateScope`, is the core mechanism of state management in `flutter_mvc`. It is responsible for creating and managing state objects (`MvcRawStore`). Not every `MvcWidget` creates an `MvcStateScope`; only those explicitly configured to do so will create one.

### Core Concepts

1.  **State Scope**:
    `MvcStateScope` allows you to create independent state containers in different parts of the widget tree. When you create a state in a new `MvcStateScope`, it does not conflict with a state of the same type in a parent scope. It can access and override states from parent scopes.

2.  **Scope Nesting and Lookup**:
    Scopes can be nested. When you try to get a state (e.g., via `context.stateAccessor.useState`), the framework first looks in the current `MvcStateScope`. If it's not found, it travels up the widget tree to the parent `MvcStateScope` and continues searching until it finds the state or reaches the root.

3.  **Root State Scope**:
    `MvcApp` creates a top-level `MvcStateScope`.

4.  **State Deletion**:
    When the widget containing the `MvcStateScope` is unmounted, all state instances within that scope are automatically deleted. Otherwise, you can only delete a specific type of state instance by calling the `deleteState<T>()` method.

### How to Create a New `MvcStateScope`

There are two main ways to create a new state scope:

1.  **Using `MvcStateScopeBuilder`**:
    This is a widget specifically designed for creating new scopes.

    ```dart
    MvcStateScopeBuilder(
      builder: (context) {
        // States created under this context will be in the new scope
        return MyWidget();
      },
    )
    ```

2.  **Setting a Flag in `MvcController` or `MvcWidgetState`**:
    By overriding the `createStateScope` property and returning `true`, you can make an `Mvc` widget or `MvcStatefulWidget` create a new state scope in its subtree. `MvcController` creates a new state scope by default.

    ```dart
    class MyController extends MvcController {
      @override
      bool get createStateScope => true; // Defaults to true

      // ...
    }

    class MyStatefulWidgetState extends MvcWidgetState {
      @override
      bool get createStateScope => true; // Defaults to false

      // ...
    }
    ```

### How to Obtain `MvcStateScope`

- By getting an instance of type `MvcStateScope` through dependency injection. When using dependency injection, be mindful of the scope rules to ensure you get the instance from the correct scope.
- In an `MvcController` or `MvcWidgetState`, you can access the `MvcStateScope` instance associated with the current widget through the `stateScope` property.
- Through the `stateScope` extension method on `BuildContext` to get the nearest state scope instance.

### Key Functions

- **Create State (`createState`)**: Creates a new state within the current scope.
- **Get State (`getState`, `getStore`)**: Gets a state instance or its storage object (`MvcRawStore`) from the current or a parent scope.
- **Update State (`setState`)**: Updates a state within the scope and notifies all listening widgets to rebuild.
- **Listen to State (`listenState`)**: Allows non-widget objects to listen to state changes.
- **Delete State (`deleteState`)**: Deletes a specific type of state instance from the current scope.

Through these two scopes, `flutter_mvc` achieves flexible decoupling and precise control between the UI layer (via `MvcWidgetScope`) and the data layer (via `MvcStateScope`).
````