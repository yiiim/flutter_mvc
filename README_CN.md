[[English](README.md),中文]

# 快速开始

## 使用MVC

分别创建`model`、`view`、`controller`

```dart

class HomeModel {
  const HomeModel(this.title);
  final String title;
}

class HomeController extends MvcController<HomeModel> {
  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Center(
      child: Text(controller.model.title),
    );
  }
}

```

在Flutter中使用Mvc

```dart
Mvc(
  create: () => HomeController(),
  model: const HomeModel('Flutter Mvc Demo'),
)
```

将会显示`Flutter Mvc Demo`的文本。

>如果你不需要Model，可以省略。

## 更新MVC

```dart
class _MyHomePageState extends State<MyHomePage> {
  String title = 'Flutter Mvc Demo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Mvc(
        create: () => HomeController(),
        model: HomeModel(title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            title = 'Flutter Mvc Demo Updated';
          });
        },
        tooltip: 'Update Title',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

点击按钮后，将会更新`HomeModel`的`title`，并且`HomeView`也会更新。

## Controller的生命周期

```dart
class HomeController extends MvcController<HomeModel> {
  @override
  void init() {
    super.init();
  }

  @override
  void didUpdateModel(HomeModel oldModel) {
    super.didUpdateModel(oldModel);
  }

  @override
  void activate() {
    super.activate();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}
```

`Controller`生命周期和`StatefulWidget`中的`State`的生命周期一致。

## 更新Widget

### 更新MvcView

```dart
class HomeController extends MvcController {
  String title = "Default Title";

  void tapUpdate() {
    title = "Title Updated";
    update();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Center(
        child: Text(controller.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapUpdate,
        tooltip: 'Update Title',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

使用`Controller`中的`update`方法可以更新整个`MvcView`。

### 根据Widget类型更新指定Widget

```dart
class HomeController extends MvcController {
  String title = "Default Title";
  String body = "Default Body";

  void tapUpdate() {
    title = "Title Updated";
    body = "Body Updated";
    querySelectorAll<MvcHeader>().update(); // update all MvcHeader, or use querySelectorAll("MvcHeader").update();
    querySelectorAll("MvcBody,MvcHeader").update(); // update all MvcBody and MvcHeader
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MvcHeader(
            builder: (_) => Text(controller.title),
          ),
          MvcBody(
            builder: (_) => Text(controller.body),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapUpdate,
        tooltip: 'Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

并不是所有的Widget都可以根据类型更新，只有继承自`MvcStatelessWidget`或`MvcStatefulWidget`的Widget才可以根据类型来更新。

```dart
class MyMvcWidget extends MvcStatelessWidget<HomeController> {
  const MyMvcWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text((context as MvcContext<HomeController>).controller.title);
  }
}

class HomeController extends MvcController {
  String title = "Default Title";

  void tapUpdate() {
    title = "Title Updated";
    querySelectorAll<MyMvcWidget>().update(); // update all MyMvcWidget. or use querySelectorAll("MyMvcWidget").update();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MyMvcWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.tapUpdate,
        tooltip: 'Update',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 根据id,class,attribute更新指定Widget

```dart
class HomeController extends MvcController {
  String title = "Default Title";

  void tapUpdateById() {
    querySelectorAll('#title_id').update(() => title = "Title Updated By Id");
  }

  void tapUpdateByClass() {
    querySelectorAll('.title_class').update(() => title = "Title Updated By Class");
  }
  void tapUpdateByAttribute() {
    querySelectorAll('[data-title]').update(() => title = "Title Updated By Attribute");
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MvcBuilder(
            id: "title_id",
            classes: const ["title_class"],
            attributes: const {"data-title": "title"},
            builder: (_) {
              return Text(controller.title);
            },
          ),
          TextButton(
            onPressed: controller.tapUpdateById,
            child: const Text("Update By Id"),
          ),
          TextButton(
            onPressed: controller.tapUpdateByClass,
            child: const Text("Update By Class"),
          ),
          TextButton(
            onPressed: controller.tapUpdateByAttribute,
            child: const Text("Update By Attribute"),
          ),
        ],
      ),
    );
  }
}
```

`querySelectorAll`遵循[web选择器规则](https://www.w3.org/TR/selectors-4)。可以使用它同时更新多个符合规则的Widget，但是它不支持同级选择器。

同时有一个静态的方法：`Mvc.querySelectorAll`，可以在任何地方更新当前Widget树上的Widget。

## 依赖注入

依赖注入是flutter_mvc的核心功能。它可以让你在框架中轻松的获取到你需要的对象。

### 概念

在flutter_mvc的依赖注入中，你只需要提供对象类型以及对象的创建方法，框架会自动的创建对象并且在需要的时候提供给你，同时它还提供了三种不同的生命周期：`单例模式`、`瞬时模式`、`作用域模式`。

单例模式，只会创建一次对象，之后的获取都会返回同一个对象。

```dart
collection.addSingleton<TestService>((_) => TestService());
```

瞬时模式，每次获取都会创建一个新的对象。

```dart
collection.add<TestService>((_) => TestService());
```

作用域模式，每次获取都会创建一个新的对象，但是在同一个作用域内获取到的对象都是同一个。

```dart
collection.addScopedSingleton<TestService>((_) => TestService());
```

作用域模式是flutter_mvc中很重要的一个概念，它可以让你在同一个作用域内获取到同一个对象，但是在不同的作用域内获取到的对象是不同的。**并且即使是单例模式，如果注入该对象的作用域销毁了，那么该对象也会被销毁。**

---

**在flutter_mvc中，每一个继承自`MvcStatefulWidget`和`MvcStatelessWidget`的Widget都是一个新的作用域，包括`Mvc`、`MvcBuilder`、`MvcHeader`、`MvcBody`、`MvcFooter`、`MvcServiceScope`等。**

注入如下对象：

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService1>((_) => TestService1());
    collection.add<TestService2>((_) => TestService2());
    collection.addScopedSingleton<TestService3>((serviceProvider) => TestService3());
  },
  child: Mvc(create: () => HomeController()),
)
```

获取对象：

```dart
class HomeController extends MvcController {
  @override
  void init() {
    super.init();
    final TestService1 service1 = getService<TestService1>();
    final TestService2 service2 = getService<TestService2>();
    final TestService3 service3 = getService<TestService3>();
  }

  @override
  MvcView<MvcController> view() => HomeView();
}

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    final TestService1 service1 = getService<TestService1>();
    final TestService2 service2 = getService<TestService2>();
    final TestService3 service3 = getService<TestService3>();

    return Scaffold(
      body: Center(
        child: MvcBuilder(
          builder: (context) {
            final TestService1 service1 = context.getService<TestService1>();
            final TestService2 service2 = context.getService<TestService2>();
            final TestService3 service3 = context.getService<TestService3>();
            return const Text("Hello, World!");
          },
        ),
      ),
    );
  }
}
```

其中所有的`TestService2`均不是同一实例，因为它是瞬时模式。

所有的`TestService1`都是同一实例，因为它是单例模式。

`Controller`中获取的`TestService3`和`MvcView`中获取的`TestService3`是同一实例，因为`Controller`和`MvcView`属于同一个作用域。但是`MvcBuilder`中通过其`context`获取的`TestService3`是一个新的实例，因为`MvcBuilder`是一个新的作用域。

再来看另外一个例子：

```dart
MvcDependencyProvider(
  key: const ValueKey('1'),
  provider: (collection) {
    collection.addSingleton<TestService1>((_) => TestService1());
    collection.add<TestService2>((_) => TestService2());
    collection.addScopedSingleton<TestService3>((serviceProvider) => TestService3());
  },
  child: Column(
    children: [
      MvcDependencyProvider(
        key: const ValueKey('2'),
        provider: (collection) {
          collection.addSingleton<TestService4>((_) => TestService4());
          collection.add<TestService5>((_) => TestService5());
          collection.addScopedSingleton<TestService6>((serviceProvider) => TestService6());
        },
        child: Mvc(create: () => HomeController()),
      ),
      MvcDependencyProvider(
        key: const ValueKey('3'),
        provider: (collection) {
          collection.addSingleton<TestService7>((_) => TestService7());
          collection.add<TestService8>((_) => TestService8());
          collection.addScopedSingleton<TestService9>((serviceProvider) => TestService9());
        },
        child: Mvc(create: () => HomeController()),
      )
    ],
  ),
)
```

Key2和Key3分别属于两个不同的作用域，它们有一个共同的父级作用域Key1。

其中`TestService2`是Key1父级中的瞬时模式，无论何时获取到的都是新的实例。

`TestService1`是Key1父级中的单例模式，在Key2和Key3以及其子级中获取均为同一实例。

`TestService3`是Key1父级中的作用域模式，在Key2和Key3中获取到的是不同实例，但是如果在Key2或Key3中多次获取或者在它们的子级中获取时获取到的是同一实例。

在Key1中无法获取到`TestService7`、`TestService8`、`TestService9`，因为它以及它的父级都没有注入这些对象，同理在Key2中无法获取到`TestService4`、`TestService5`、`TestService6`。

---

关于依赖注入的更多功能可以参考[dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)，里面有更多有趣的用法。

### 注入对象

有很多种方法可以注入对象。

如前文所说的使用`MvcDependencyProvider`注入对象。

```dart
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: const MyApp(),
)
```

---

在`Controller`中注入对象。

```dart
class HomeController extends MvcController {
  @override
  void initServices(ServiceCollection collection, ServiceProvider parent) {
    super.initServices(collection, parent);
    collection.addSingleton<TestService>((_) => TestService());
  }
}
```

---

使用`MvcStatefulWidget`注入对象。

```dart
class TestMvcStatefulWidget extends MvcStatefulWidget {
  MvcWidgetState createState() => TestMvcStatefulState();
}
class TestMvcStatefulState extends MvcWidgetState {
  @override
  void initServices(ServiceCollection collection, ServiceProvider parent) {
    super.initServices(collection, parent);
    collection.addSingleton<TestService>((_) => TestService());
  }
}
```

---

每一个`Mvc`都已经以单例模式默认注入了`MvcController`和`MvcView`。

### 获取对象

获取对象时可以获取当前作用域以及其所有上级作用域注入的对象。

任何通过依赖注入注入的对象都可以通过混入`DependencyInjectionService`然后通过`getService`方法获取对象。在flutter_mvc中，`MvcController`、`MvcView`、`MvcWidgetState`均符合这个条件。也可以通过注入的对象来获取，例如：
  
```dart
class TestService with DependencyInjectionService {
  void test() {
    final HomeController controller = getService<HomeController>();
    controller.update();
  }
}
```

正如上面的代码所示，你可以在注入的对象中随时获取到你想要的`Controller`，但是请一定注意作用域。

---

还可以通过context来获取对象。

```dart
class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            final TestService service = context.getMvcService<TestService>();
            return const Text("Hello, World!");
          },
        ),
      ),
    );
  }
}
```

context获取的范围为当前上下文最近的一个MvcWidget所在的作用域。

### 对象的生命周期

对象的生命周期方法仅限混入了`DependencyInjectionService`的对象。

---

- 初始化

当对象被创建时会立即同步执行`dependencyInjectionServiceInitialize`，每一个实例仅执行一次。这个方法可以异步。当`dependencyInjectionServiceInitialize`是异步方法时，获取对象之后可以通过`await waitLatestServiceInitialize()`或者`await waitServicesInitialize()`来等待初始化完成。其中`waitLatestServiceInitialize`仅等待当前运行循环内最近获取的对象初始化完成，`waitServicesInitialize`是等待当前所有的初始化完成。

---

- 销毁

当对象所在范围被销毁时会执行**由该范围创建的**对象的`dispose`方法。有一个例外时如果是瞬时模式的对象，当不在使用时随时可能被GC清楚，并且不会执行其`dispose`方法。

### 使用依赖注入的对象来更新Widget

如果注入的对象混入了`MvcService`，那么可以通过一些方法来更新Widget。

---

使用`MvcServiceScope`

```dart
class TestService with DependencyInjectionService, MvcService {
  String title = "title";
  void test() {
    update(() => title = "new title");
  }
}
MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: Scaffold(
    body: MvcServiceScope<TestService>(
      builder: (MvcContext context, TestService service) {
        return Text(service.title);
      },
    ),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<TestService>().test();
          },
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
)
```

点击按钮将会更新`Text`的内容。

---

如果你有一个`MvcContext`，也可以将它依赖到对象。

```dart
class TestService with DependencyInjectionService, MvcService {
  String title = "title";
  void test() {
    update(() => title = "new title");
  }
}

class TestWidget extends MvcStatelessWidget {
  const TestWidget({super.key, super.id, super.classes});

  @override
  Widget build(BuildContext context) {
    return Text((context as MvcContext).dependOnService<TestService>().title);
  }
}

MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: Scaffold(
    body: const TestWidget(),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<TestService>().test();
          },
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
)
```

`MvcStatelessWidget`和`MvcWidgetState`的`build`方法中的`context`可以强制转换为`MvcContext`，并且`MvcWidgetState`的`context`返回的也是`MvcContext`。

另外`MvcService`也有`querySelectorAll`方法，你可以使用它来查找并更新Widget。它查找逻辑是以依赖它的Widget为根节点进行查找。

```dart
class TestService with DependencyInjectionService, MvcService {
  String title = "title";
  void test() {
    querySelectorAll('#title').update(
      () {
        title = "new title";
      },
    );
  }
}

MvcDependencyProvider(
  provider: (collection) {
    collection.addSingleton<TestService>((_) => TestService());
  },
  child: Scaffold(
    body: MvcServiceScope<TestService>(
      builder: (MvcContext context, TestService service) {
        return Column(
          children: [
            MvcBuilder(
              id: "title",
              builder: (MvcContext context) {
                return Text(service.title);
              },
            ),
          ],
        );
      },
    ),
    floatingActionButton: Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () {
            context.getMvcService<TestService>().test();
          },
          child: const Icon(Icons.add),
        );
      },
    ),
  ),
)
```

上面的代码也可以更新`Text`的内容。

---

同一个`MvcService`可以存在多个依赖的Widget，调用`update`方法时它们都会更新。调用`querySelectorAll`方法时将会分别以它们为根节点进行查找，结果为它们的并集。
