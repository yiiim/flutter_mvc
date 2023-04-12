# Flutter Mvc

语言: [English](https://github.com/yiiim/flutter_mvc) | 中文

Flutter Mvc 是一个包含了UI与逻辑分离、状态管理、依赖注入的Flutter框架。

- [快速开始](#快速开始)
- [Mvc](#mvc)
  - [Model](#model)
  - [View](#view)
  - [Controller](#controller)
    - [创建Controller](#创建controller)
    - [创建无View的Controller](#创建无view的controller)
    - [Controller生命周期](#controller生命周期)
    - [获取其他Controller](#获取其他controller)
    - [从任意地方获取Controller](#从任意地方获取controller)
    - [MvcControllerPart](#mvccontrollerpart)
- [状态管理](#状态管理)
  - [示例](#示例)
  - [MvcStateScope](#mvcstatescope)
  - [MvcStateProvider](#mvcstateprovider)
  - [MvcStateValue](#mvcstatevalue)
  - [初始化状态](#初始化状态)
  - [获取状态](#获取状态)
  - [更新状态](#更新状态)
  - [删除状态](#删除状态)
  - [StatePart](#statepart)
  - [Model状态](#model状态)
- [依赖注入](#依赖注入)
  - [MvcDependencyProvider](#mvcdependencyprovider)
  - [获取依赖](#获取依赖)
  - [服务范围](#服务范围)
  - [buildScopedService](#buildscopedservice)

## 快速开始

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

## Mvc

### Model

在Mvc中，对Model没有任何限制，可以为任意类型，也可以为空，Model的主要作用是在```Mvc```被外部重新构建时，需要传入新的值，必须通过Model来传递。```Mvc```的```create```只会在挂载时执行一次，```Mvc```更新时不会重复创建Controller。**所以不要使用Controller的构造函数来传递构建时更新的参数，而是使用Model传递**。在```Mvc```被外部重建时，将会收到Model状态更新，有关Model状态更新，请阅读[此处](#model状态)

### View

View由Controller返回，使用如下方式创建：

```dart
class IndexPage extends MvcView<IndexPageController, IndexPageModel> {
  @override
  Widget buildView(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.model.title),
      ),
      body: Center(
        child: Text(context.controller.content),
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

### Controller

#### 创建Controller

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

#### 创建无View的Controller

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

#### Controller生命周期

在```Mvc```被挂载时，会通过```create```参数创建Controller，Controller的生命周期为：

* 在创建Controller之后，会对Controller执行一些必要的准备工作，之后立即执行Controller的```init```方法
* 在```Mvc```更新时，Controller并没有生命周期方法，而是触发Controller中的Model状态更新
* ```Mvc```在卸载时执行```dispose```方法。

不要将同一个Controller实例传递给多个Mvc，这样会导致Controller的生命周期方法仅会依赖首个挂载的```Mvc```触发。

#### 获取其他Controller

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

如非必要不要传递```sort```为true，```sort```可以保证在获取同级的Controller时保证获取的顺序（以Mvc所处的多子级Element的solt排序），但是它会增加性能消耗，如果不保证顺序，同级的Controller排序为挂载顺序。

#### 从任意地方获取Controller

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

#### MvcControllerPart

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

在Controller中添加```Part```,实现```buildPart```方法，在```buildPart```方法中添加：

```dart
@override
void buildPart(MvcControllerPartCollection collection) {
  super.buildPart(collection);
  collection.addPart<IndexPageControllerBannerPart>(() => IndexPageControllerBannerPart());
}
```

同一个Controller可以添加多个```Part```,但是同类型的仅可添加一个

从Controller中获取```Part```：

```dart
part<IndexPageControllerBannerPart>()
```

获取时使用的泛型类型必须与注册时使用的一致。

---

```Part```具有如下特性：

* ```Part```的```init```和```dispose```方法在Controller之后执行。

* 每个```Part```中都可以获取它所属的Controller

* 每个```Part```中都有自己的状态，在```Part```中使用状态和Controller类似，有关```Part```状态相关的文档可以阅读此处：[StatePart](#statepart)。

## 状态管理

### 示例

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

在更新状态时如果```MvcStateScope```曾获取过该状态，则```MvcStateScope```将会重建。

### MvcStateScope

```MvcStateScope```的定义如下所示：

```dart
class MvcStateScope<TControllerType extends MvcController> extends Widget {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);

  final Widget Function(MvcWidgetStateProvider state) builder;

  final MvcStateProvider? stateProvider;

  final Widget? child;
}
```

**builder** 状态更新时重建的builder

**stateProvider** 状态提供者，通常为```MvcController```，如果为空，则状态提供者为离```MvcStateScope```最近的类型为泛型```TControllerType```的```MvcController```

**child** 在状态更新时，如果有不需要更新的Widget，通过这个参数传递，可以通过```builder```方法中的参数获取，用于节省性能

builder方法中的参数```MvcWidgetStateProvider```可以**获取状态提供者提供的全部状态**，并且一旦**通过它获取过的状态更新时，Widget就会更新**。即使是通过```Builder```来获取过的状态，也可以获得更新。如下所示：

```dart
MvcStateScope<IndexPageController>(
  (MvcWidgetStateProvider state) {
    return Builder(
      builder: (context) {
        return Text("${state.get<int>()}");
      },
    );
  },
)
```

### MvcStateProvider

状态提供者```MvcStateProvider```的定义如下：

```dart
abstract class MvcStateProvider {
  T? getState<T>({Object? key});

  MvcStateValue<T>? getStateValue<T>({Object? key});
}
```

它是一个抽象接口，任何实现该接口的类都可以为```MvcStateScope```提供状态，在Mvc中```MvcController```实现了该接口。状态相关的操作均在```MvcController```中进行。

### MvcStateValue

在Mvc中，状态的类型为```MvcStateValue<T>```

```dart
class MvcStateValue<T> extends ChangeNotifier {
  MvcStateValue(this.value);
  T value;

  void update() => notifyListeners();
}
```

它是一个类似于```ValueNotifier```的类，不过并不会在每次setValue的发送通知，仅会在调用```update()```方法时发送。这里可以理解为**每次```update()```时触发状态更新**。

### 初始化状态

方法定义

```dart
MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public})
```

使用示例

```dart
initState<int>(0)
```

在Controller中任何时候都可以使用```initState```来初始化一个新的状态，状态将会保存在Controller中直至删除或者Controller销毁。

**key** 状态标识，**在同一个Controller中状态依靠泛型类型+```key```的hashCode来区分唯一性**

**accessibility** 状态的访问级别：

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
* private，当前Controller以及的ControllerPart可以获取到该状态
* internal，只有状态创建者才可以获取该状态

在一个Controller实例中同一个状态只能初始化一次，泛型类型和key的hashCode相同即表示同一个状态。

### 获取状态

可以在Controller中获取状态，方法为：

```dart
T? getState<T>({Object? key, bool onlySelf = false});
```

使用示例

```dart
var state = getState<int>()
```

获取状态时，根据初始化状态时的Key和状态类型来查找状态。查找状态不仅会查找当前Controller初始化的状态，还会依次查找父级中访问级别为```public```以上的状态，如果查找到最顶级还没有找到，则会查找当前所有Controller中访问级别为```global```的状态。简单的说就是可以获取到当前全部可访问的状态。

在使用```MvcStateScope```获取状态时，是```MvcStateProvider```获取，在Mvc中即为```MvcController```，```MvcWidgetStateProvider```是```MvcStateProvider```的包装。

如果状态不存在则会返回null，但是如果状态本身为null，你可以使用```getStateValue```方法来获取返回的```MvcStateValue```，如果```MvcStateValue```为null则表示没有获取到该状态，如果```MvcStateValue```不为null，则它的```value```属性就是状态值

### 更新状态

```dart
MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key})
```

使用示例

```dart
updateState<int>(updater:(state)=>state.value++);
```

**updater** 在该方法中可以将状态设置为新的值，即使不设置，也会触发状态更新

**key** 和获取状态一样，需要更新的状态的标识

在Controller中调用，如果没有获取到要更新的状态则返回null，仅可更新自己创建的状态。

### 删除状态

```dart
void deleteState<T>({Object? key});
```

同样在Controller中调用，仅可删除自己创建的状态。

### StatePart

在使用Key和类型作为状态的唯一标识时，当相同类型的状态过多时，可能需要创建很多的Key，造成代码的混乱不堪，为了减轻这种状况，提供了一个具有Part的状态提供接口

```dart
abstract class MvcHasPartStateProvider extends MvcStateProvider {
  T? getStatePart<T extends MvcStateProvider>();
}
```

这个接口可以根据类型返回另一个状态提供者。

```MvcController```同样实现了这个接口，在```MvcController```的实现中，返回的每个```Part```状态提供者中都使用了独立的状态，也就是说每个```Part```中都可以初始化同样类型同样Key的状态。但是在```Part```中只能初始化访问级别为```internal```的状态，```internal```的状态只能通过其自身获取，所以在获取```Part```中的状态时，需要先获取该```Part```然后再获取状态，在```MvcController```获取```Part```时，将会从自己开始往父级查找，直到找到指定类型的```Part```。获取```Part```中的状态的方法定义为：

```dart
getStatePart<TPartType>().getState<TStateType>(key:key)
```

使用方式：

```dart
indexPageController.getStatePart<IndexPageControllerBannerPart>().getState<int>(key:IndexPageControllerBannerPartKeys.bannerIndex)
```

它会从当前Controller开始往父级查找类型为```TPartType```，然后使用```TPartType```获取状态。如果```TPartType```中没有找到状态，则再交给```TPartType```所属的```MvcController```去获取

在```MvcStateScope```中使用：

```dart
state.part<IndexPageControllerBannerPart>().get<int>(key:IndexPageControllerBannerPartKeys.bannerIndex)
```

在```MvcStateScope```中使用时，仅当```MvcStateScope```所使用的```MvcStateProvider```是```MvcHasPartStateProvider```时才有效，否则返回null。在上面代码```part```是对```getStatePart```的包装，```get```是对```getState```的包装。

```MvcController```实现的```Part```类型为```MvcControllerPart```，有关```MvcControllerPart```的创建与使用可以阅读此处[MvcControllerPart](#mvccontrollerpart)

### Model状态

在Controller中可以直接使用model属性获取Model，Model是一个key为null类型为泛型```TModelType```的状态，也可以使用获取状态的方式获取，Model状态会在Controller所属的```Mvc```被外部重建时更新

获取model状态：

```dart
var model = getState<TModelType>();
```

如果在View中有依赖外部Model更新的，可以通过获取Model状态来更新UI。

```dart
MvcStateScope<IndexPageController>(
    (MvcWidgetStateProvider state) {
        return Text("${state.get<TModelType>()}");
    },
)
```

如果在Controller中有依赖外部Model更新的逻辑，可以监听Model状态：

```dart
getStateValue<TModelType>()?.addListener(() {});
```

## 依赖注入

依赖注入使用[https://github.com/yiiim/dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)实现

建议在阅读以下文档之前先阅读[dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)文档

### MvcDependencyProvider

使用```MvcDependencyProvider```向子级注入依赖

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<Object>((serviceProvider) => Object());
    collection.addScopedSingleton<Object>((serviceProvider) => Object());
    collection.add<Object>((serviceProvider) => Object());
  },
  child: ...,
);
```

```addSingleton```，表示注入单例，所有子级获取该类型的依赖时，都为同一个实例

```addScopedSingleton```，表示注入范围单例，在Mvc中，每个Mvc都有自己的范围服务，这种类型的依赖，在不同的Controller实例中获取的都是不同实例，是在同一个Controller实例中获取的是同一个实例

```add```，注入普通服务，每次获取均为重新创建实例

还可以注入```MvcController```，注入```MvcController```后在使用```Mvc```时可以不用传递```create```参数，```Mvc```会从依赖注入中创建Controller。

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addController<IndexPageController>((provider) => IndexPageController());
  },
  child: Mvc<IndexPageController,IndexPageModel>(model: IndexPageModel()),
);
```

### 获取依赖

任何由依赖注入创建的服务都可以混入```DependencyInjectionService```来获取其他注入的服务，在MvcController中也可以。获取服务的方法定义如下：

```dart
T getService<T extends Object>();
```

泛型类型必须与注入服务时使用的泛型类型一致。

### 服务范围

每一个MvcController都会在创建时**使用它父级MvcController范围**生成一个服务范围，如果没有父级则使用```MvcOwner```。在Controller所在的服务范围中，默认注册了```MvcController```、```MvcContext```、```MvcView```三个类型的单例服务，其中```MvcController```为Controller本身，```MvcContext```为Controller所在的```Element```，```MvcView```使用Controller创建。服务范围会在Controller销毁时释放

## buildScopedService

```dart
@override
void buildScopedService(ServiceCollection collection) {
    collection.add<Object>((serviceProvider) => Object());
}
```

在Controller中重写```buildScopedService```方法可以在生成该Controller的服务范围时，向该范围注入额外的服务，由于创建服务范围时是基于父级创建的，所以这些额外的服务子级可以获取。

有关依赖注入的更多使用方式请阅读：[dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)文档
