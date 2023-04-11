# Mvc

使用Mvc的方式非常简单，直接使用```Mvc```这个```Widget```即可。例如：

```dart
Mvc(
    create: () => IndexPageController(),
    model: IndexPageModel(title: "Flutter Demo"),
)
```

然后在Controller中处理逻辑，返回View，Model参数将会作为Controller的属性获取。

如果Model参数并不是必须的，你可以更简单的使用

```dart
Mvc(create: () => IndexPageController())
```

## Model

在Mvc中，对Model没有任何限制，可以为任意类型，也可以为空，Model的主要作用是在```Mvc```被外部重新构建时，需要传入新的值，必须通过Model来传递。```Mvc```的```create```只会在挂载时执行一次，```Mvc```更新时不会重复创建Controller。**所以不要使用Controller的构造函数来传递构建时更新的参数，而是使用Model传递**。

## View

View由Controller返回，使用如下方式创建：

```dart
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ctx.model.title),
      ),
      body: Center(
        child: Text(ctx.controller.content),
      ),
    );
  }
}
```

它有两个泛型参数，一个为Model的类型，一个为Controller的类型，以及一个```buildView```方法返回UI。

在```buildView```方法中可以通过参数```context```获取到它的Controller和Model，使用它们来构建UI。

如果不需要麻烦的Model，可以使用```MvcModelessView<TControllerType extends MvcController>```，它只有一个Controller的泛型类型。

```dart
class IndexPage extends MvcModelessView<IndexPageController> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      body: Center(
        child: Text(ctx.controller.content),
      ),
    );
  }
}
```

如果使用```MvcModelessView```，就不能访问model。

---

在```buildView```中配合```MvcStateScope```来获取状态，专注于UI的构建而无需处理逻辑，下面是一个简单的示例：

```dart
class IndexPage extends MvcModelessView<IndexPageController> {
  @override
  Widget buildView(ctx) {
    return Scaffold(
      body: Center(
        child: MvcStateScope<IndexPageController>(
            (state) {
                return Text("current number is: ${state.get<int>()}");
            },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctx.controller.incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      )
    );
  }
}
```

逻辑和状态管理交给Controller，View通过Controller提供的状态构建UI

关于状态详细文档可以阅读此处： [Mvc的状态管理](../)

## Controller

### 创建Controller

继承自```MvcController```，实现```view```方法返回```MvcView```

```dart
class IndexPageController extends MvcController<IndexPageModel> {
  @override
  void init() {
    super.init();
  }

  @override
  MvcView view(model) {
    return IndexPage();
  }
}
```

返回View时需要注意，返回的```MvcView```的泛型Controller和Model类型必须与Controller匹配

### 创建无View的Controller

继承 ```MvcProxyController```

```dart
class IndexDataController extends MvcProxyController {
  @override
  void init() {
    super.init();
  }
}
```

无View的Controller使用```MvcProxy```来挂载

```dart
MvcProxy(
    proxyCreate: () => IndexDataController(),
    child: ...,
)
```

```MvcProxyController```无需返回View，可以专注于逻辑的处理，而无需返回View，但它仍然可以向子级提供状态。这在有些时候很有用。

### Controller生命周期

在```Mvc```被挂载时，会通过```create```参数创建Controller，Controller的生命周期为：

* 在创建Controller之后，会对Controller执行一些必要的准备工作，之后立即执行Controller的```init```方法
* 在```Mvc```更新时，Controller并没有生命周期方法，而是触发Controller中的Model状态更新
* ```Mvc```在卸载时执行```dispose```方法。

不要将同一个Controller实例传递给多个Mvc，这样会导致Controller的生命周期方法仅会依赖首个挂载的```Mvc```触发。

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

如非必要不要传递```sort```为true，```sort```可以保证在获取同级的Controller时保证获取的顺序，但是它会增加性能消耗，如果不保证顺序，同级的Controller排序为挂载顺序。

### 从任意地方获取Controller

使用Mvc的静态方法可以从当前全部的```Mvc```中获取指定类型的Controller

```dart
static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where});
```

使用方式如下：

```dart
var controller = Mvc.get<IndexPageController>();
```

**context** 如果传入```context```参数，则查找离该context父级中最近的Controller。

**where** 表示如果指定类型的Controller存在多个时，可以使用该参数筛选。

### MvcControllerPart

当Controller中逻辑较多或者状态较多时，可以将一些独立的逻辑移入```MvcControllerPart```，使用方式如下：

创建一个```MvcControllerPart```：

```dart
class IndexPageControllerBannerPart extends MvcControllerPart<IndexPageController> {
  @override
  void init() {
    super.init();
  }
}
```

在Controller中注册```Part```：

```dart
registerPart<IndexPageControllerBannerPart>(IndexPageControllerBannerPart());
```

同一个Controller可以注册多个```Part```,但是同类型的仅可注册一个

从Controller中获取```Part```：

```dart
part<IndexPageControllerBannerPart>()
```

获取时使用的泛型类型必须与注册时使用的一致。

---

```Part```具有如下特性：

* ```Part```的```init```方法在注册时立即执行，```dispose```方法在Controller```dispose```执行。

* 每个```Part```中都可以获取它所属的Controller

* 每个```Part```中都有自己的状态，在```Part```中使用状态和Controller类似，有关```Part```状态相关的文档可以阅读此处：[StatePart](./Status/#StatePart)。
