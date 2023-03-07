# Flutter Mvc

Flutter Mvc 是为了解决UI与逻辑分离的一个状态管理框架.

## Getting started

分别创建```Model，MvcView<TModelType,TControllerType>，MvcController<TModelType>```

```dart
/// Model
class IndexPageModel {
  IndexPageModel({required this.title});
  final String title;
}
/// Controller
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  MvcView view(IndexPageModel model) {
    return IndexPage();
  }
}
/// View
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(context) {
    //...
  }
}
```

然后使用```Mvc```

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Mvc<IndexPageController, IndexPageModel>(
        create: () => IndexPageController(),
        model: IndexPageModel(title: "Flutter Mvc Demo"),
      ),
    );
  }
}
```

## 状态管理

首先在Controller的init方法中初始化状态

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0);
  }
}
```

在View中使用状态

```dart
Widget buildView(context) {
  return MvcStateScope<IndexPageController>(
    (state) {
      return Text("${state.get<int>()}");
    },
  );
}
```

在Controller中更新状态

```dart
updateState<int>(updater: ((state) => state.value++));
```

在更新状态时如果```MvcStateScope```曾获取过该状态，则```MvcStateScope```将会重建。如果在```MvcStateScope```区域中使用的多个状态，则任意状态发生更新这个```MvcStateScope```都会重建。

## Controller

### 初始化状态

```dart
MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public})
```

任何时候都可以使用```initState```来初始化一个新的状态，状态将会保存在Controller中。

**key**，状态标识，**在同一个Controller中状态依靠泛型类型以及```key```的hashCode来区分唯一性**

**accessibility**，状态的访问级别：

```dart
enum MvcStateAccessibility {
  /// 全局的
  global,

  /// 公开的
  public,

  /// 私有的
  private,

  /// 内部的
  internal,
}
```

* global，任何Controller都可以获取到该状态
* public，当前Controller以及他的子级可以获取到该状态，默认为public
* private，当前Controller以及他的Part可以获取到该状态
* internal，只有状态创建者才可以获取该状态

### 获取状态

```dart
T? getState<T>({Object? key, bool onlySelf = false});
```

**key**参数为状态标识

**onlySelf**表示仅从当前Controller获取状态，如果为false，它会尝试从任何地方获取它可以访问的状态，默认为false

如果状态不存在则会返回null，但是如果状态本身为null，你可以使用```getStateValue```方法来获取返回的```MvcStateValue```，如果```MvcStateValue```为null则表示没有获取到改状态，如果```MvcStateValue```不为null，则它的value属性就是状态值

### 更新状态

```dart
MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key})
```

**updater**在改方法中可以将状态设置为新的值，不过即使不设置，也会触发状态更新

**key**和获取状态一样，需要更新的状态的标识

如果没有获取到要更新的状态则返回null，仅可更新自己创建的状态

### 删除状态

```dart
void deleteState<T>({Object? key});
```

### 状态总结

Controller主要职责就是处理逻辑，管理状态。

在Controller中无需处理UI相关的事情，只需要管理好状态，然后交由UI使用，同时UI只需获取状态然后根据状态展示UI，UI甚至都不需要知道状态是由谁提供的。状态的可访问级别可以让Controller中的状态可以被更多的想要获取的UI组件获取。Controller无需理会谁会获取状态，只需要管理谁可以获取状态即可。

### Model

在Controller中可以直接使用model属性获取Model，Model也是一个状态，也可以使用获取状态的方式获取（key为null），当Controller所属的Mvc被外部重建时Model状态将会更新

### MvcControllerPart

当Controller中逻辑较多时，可以将一些独立的逻辑移入```Part```，在Controller中注册```Part```：

```dart
void registerPart<TPartType extends MvcControllerPart>(TPartType part);
```

每个```Part```中都有自己的状态，在```Part```中使用状态和Controller类似，并且```Part```中的状态和它的Controller中的状态并不冲突，他们可以初始化同样类型同样key的状态，```Part```中除了访问级别为internal外的状态都可以被Controller获取。

但是在Controller中获取时，将会优先获取Controller自己的状态，如果需要优先获取Part中的状态，则可以先获取```Part```，然后使用```Part```获取状态，在Controller中获取Part的方式为：

```dart
TPartType? part<TPartType extends MvcControllerPart>({bool tryGetFromParent = true})
```

**tryGetFromParent**表示是否获取父级Controller的Part

### 获取其他Controller

在Controller中可以获取当前Controller父级、同级、子级Controller

```dart
/// 从父级查找指定类型的Controller
T? parent<T extends MvcController>() => context.parent<T>();

/// 在直接子级查找指定类型的Controller
T? child<T extends MvcController>({bool sort = false}) => context.child<T>(sort: sort);

/// 从所有子级中查找指定类型的Controller
T? find<T extends MvcController>({bool sort = false}) => context.find<T>(sort: sort);

/// 在同级中查找前面的Controller
T? previousSibling<T extends MvcController>({bool sort = false}) => context.previousSibling<T>(sort: sort);

/// 在同级中查找后面的Controller
T? nextSibling<T extends MvcController>({bool sort = false}) => context.nextSibling<T>(sort: sort);

/// 在同级中查找Controller
T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) => context.sibling<T>(sort: sort);

/// 向前查找，表示查找同级前面的和父级，相当于[previousSibling]??[parent]
T? forward<T extends MvcController>({bool sort = false}) => context.forward<T>(sort: sort);

/// 向后查找，表示查找同级后面的和子级，相当于[nextSibling]??[find]
T? backward<T extends MvcController>({bool sort = false}) => context.backward<T>(sort: sort);
```

### 从任意地方获取Controller

使用Mvc的静态方法获取当前Element树中的任意Controller

```dart
static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where});
```

## MvcStateScope

```MvcStateScope```依靠```InheritedWidget```获取最近的指定类型的Controller，如果没有指定类型，则获取最近的```MvcController```，```builder```方法中的参数获取状态即从该Controller获取

## MvcProxy

 可以使用```MvcProxyController```来作为一个只有逻辑没有UI的Controller，使用方式为：

```dart
MvcProxy(
  proxyCreate: () => Controller(),
  child: ...,
)
```

如果有很多个这样的Controller

```dart
MvcMultiProxy(
    proxyCreate: [
      () => Controller1(),
      () => Controller2(),
    ],
    child: ...,
),
```

即使没有UI，MvcProxyController同样是树中的一个节点

## View

MvcView的原型为

```dart
abstract class MvcView<TControllerType extends MvcController<TModelType>, TModelType> {
  Widget buildView(MvcContext<TControllerType, TModelType> ctx);
}
```

参数```MvcContext```中可以获取强类型的Controller和Model

---

## 完整样例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Mvc<IndexPageController, IndexPageModel>(
        create: () => IndexPageController(),
        model: IndexPageModel(title: "Flutter Demo"),
      ),
    );
  }
}

/// Model
class IndexPageModel {
  IndexPageModel({required this.title});
  final String title;
}

/// View
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ctx.model.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            MvcStateScope<IndexPageController>(
              (state) {
                return Text("${state.get<int>()}");
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctx.controller.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Controller
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
    initState<int>(0); // 初始化状态
  }

  void incrementCounter() {
    updateState<int>(updater: ((state) => state?.value++)); // 更新状态
  }

  @override
  MvcView view(model) {
    return IndexPage();
  }
}
```
