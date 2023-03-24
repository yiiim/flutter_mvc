part of '../flutter_mvc.dart';

/// MvcController实现该类，可以为子级Mvc提供服务
abstract class MvcServiceScopedBuilder {
  void serviceScopedBuild(ServiceCollection collection);
}
