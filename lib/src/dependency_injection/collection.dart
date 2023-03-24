part of '../flutter_mvc.dart';

/// MvcController容器
abstract class MvcControllerCollection {
  void addController<T extends MvcController>(T Function() create);
}

class MvcServiceCollection extends ServiceCollection implements MvcControllerCollection {
  @override
  void addController<T extends MvcController>(T Function() create) {
    add<T>((serviceProvider) => create());
  }
}
