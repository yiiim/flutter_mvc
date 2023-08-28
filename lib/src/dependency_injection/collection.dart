part of '../flutter_mvc.dart';

/// 用来承载MvcController工厂的容器
class _MvcControllerFactoryProvider<T extends MvcController> extends MvcControllerProvider<T> {
  _MvcControllerFactoryProvider(this.factory);
  final T Function() factory;
  @override
  T create() => factory();
}

class MvcServiceCollection extends ServiceCollection {
  void addController<T extends MvcController>(T Function(ServiceProvider provider) create) {
    add<MvcControllerProvider<T>>((serviceProvider) => _MvcControllerFactoryProvider<T>(() => create(serviceProvider)));
  }
}