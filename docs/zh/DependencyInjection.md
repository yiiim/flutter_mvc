# 依赖注入

依赖注入使用[https://github.com/yiiim/dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)实现

建议在阅读以下文档之前先阅读[dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection)文档

## 注入依赖

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

## 获取依赖

任何由依赖注入创建的服务都可以混入```DependencyInjectionService```来获取其他注入的服务，在MvcController中也可以。获取服务的方法定义如下：

```dart
T getService<T extends Object>();
```

泛型类型必须与注入服务时使用的泛型类型一致。

## 服务范围

每一个MvcController都会在创建时**使用它父级MvcController范围**生成一个服务范围，如果没有父级则使用```MvcOwner```。在Controller所在的服务范围中，默认注册了```MvcController```、```MvcContext```、```MvcView```三个类型的单例服务，其中```MvcController```为Controller本身，```MvcContext```为Controller所在的Element，```MvcView```使用Controller创建。

## MvcbuildScopedServiceer

```dart
abstract class MvcbuildScopedServiceer {
  void buildScopedService(ServiceCollection collection);
}
```

在Controller中实现```MvcbuildScopedServiceer```接口可以通过```buildScopedService```方法在生成该Controller的服务范围时，向该范围注入额外的服务，由于创建服务范围时是基于父级创建的，所以这些额外的服务子级可以获取。
