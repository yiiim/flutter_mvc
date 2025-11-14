# 作用域

`flutter_mvc` 中有两个比较重要的作用域概念，分别是 `MvcWidgetScope` 和 `MvcStateScope`。

## MvcWidgetScope

与每个 `MvcWidget`（即 `MvcStatelessWidget`、`MvcStatefulWidget`、`Mvc`等）都有一个与之对应的`MvcWidgetScope`，它提供了与该特定控件实例交互的能力。

### 主要功能

1.  **访问上下文 (`BuildContext`)**:
    通过 `widgetScope.context` 可以获取当前控件的 `BuildContext`。

2.  **控件查询 (`querySelector`, `querySelectorAll`)**:
    这是 `flutter_mvc` 选择器功能的核心。你可以从任何 `MvcWidgetScope` 开始，使用类似 CSS 的选择器语法来查找树中的其他 `MvcWidget`。

    ```dart
    // 在 Controller 或 MvcWidgetState 中
    // 查找所有 class 为 'highlight' 的控件
    widgetScope.querySelectorAll('.highlight').update();
    ```

3.  **触发重建 (`update`)**:
    调用 `widgetScope.update()` 方法会标记当前控件需要重建，这在需要从外部精确控制某个 `MvcWidget` 的刷新时非常有用。

### 如何获取

- 在 `MvcController` 或 `MvcWidgetState` 中，可以直接通过 `widgetScope` 属性访问。
- 通过依赖注入获取类型为`MvcWidgetScope`的实例。通过依赖注入获取时需要注意作用域规则，确保你获取的是正确作用域中的实例。

## MvcStateScope

状态作用域`MvcStateScope` 是 `flutter_mvc` 状态管理的核心机制。它负责创建、管理状态对象 (`MvcRawStore`)。并不是每个 `MvcWidget` 都会创建一个`MvcWidgetScope`，只有那些明确配置为创建状态作用域的控件才会创建它。

### 核心概念

1.  **状态作用域**:
    `MvcStateScope` 允许你在控件树的不同部分创建独立的状态容器。当你在一个新的 `MvcStateScope` 中创建一个状态时，它不会与父级作用域中相同类型的状态冲突。它可以获取和覆盖父级作用域中的状态。

2.  **作用域嵌套和查找**:
    作用域可以嵌套。当你尝试获取一个状态时（例如通过 `context.stateAccessor.useState`），框架会首先在当前 `MvcStateScope` 中查找。如果找不到，它会沿着控件树向上，到父级 `MvcStateScope` 中继续查找，直到找到为止或到达根部。

3.  **根状态作用域**:
    `MvcApp` 会创建一个顶级的 `MvcStateScope`。

4.  **状态删除**:
    `MvcStateScope`所在的 Widget 卸载时，会自动删除该作用域内的所有状态实例。否则只能通过调用 `deleteState<T>()` 方法来删除特定类型的状态实例。

### 如何创建新的 `MvcStateScope`

有两种主要方式可以创建一个新的状态作用域：

1.  **使用 `MvcStateScopeBuilder`**:
    这是一个专门用于创建新作用域的控件。

    ```dart
    MvcStateScopeBuilder(
      builder: (context) {
        // 在此 context 下创建的状态将位于新的作用域中
        return MyWidget();
      },
    )
    ```

2.  **在 `MvcController` 或 `MvcWidgetState` 中设置标志**:
    通过重写 `createStateScope` 属性并返回 `true`，可以让 `Mvc` 控件或 `MvcStatefulWidget` 在其子树中创建一个新的状态作用域。`MvcController` 默认会创建新的状态作用域。

    ```dart
    class MyController extends MvcController {
      @override
      bool get createStateScope => true; // 默认为 true

      // ...
    }

    class MyStatefulWidgetState extends MvcWidgetState {
      @override
      bool get createStateScope => true; // 默认为 false

      // ...
    }
    ```

### 如何获取 `MvcStateScope`

- 通过依赖注入获取类型为`MvcStateScope`的实例。通过依赖注入获取时需要注意作用域规则，确保你获取的是正确作用域中的实例。
- 在 `MvcController` 或 `MvcWidgetState` 中，可以通过 `stateScope` 属性访问当前控件关联的 `MvcStateScope` 实例。
- 通过 `BuildContext` 的扩展方法 `stateScope` 获取最近的状态作用域实例。

### 主要功能

- **创建状态 (`createState`)**: 在当前作用域内创建一个新的状态。
- **获取状态 (`getState`, `getStore`)**: 获取当前或父级作用域中的状态实例或其存储对象 (`MvcRawStore`)。
- **更新状态 (`setState`)**: 更新作用域内的状态，并通知所有监听该状态的控件进行重建。
- **监听状态 (`listenState`)**: 允许非控件对象监听状态变化。
- **删除状态 (`deleteState`)**: 删除当前作用域内的特定类型状态实例。

通过这两个作用域，`flutter_mvc` 实现了 UI 层（通过 `MvcWidgetScope`）和数据层（通过 `MvcStateScope`）的灵活解耦和精确控制。
