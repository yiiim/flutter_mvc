part of 'flutter_mvc.dart';

/// MvcController实现该类，可以为子级提供MvcController
abstract class MvcControllerScopedBuilder extends MvcServiceScopedBuilder {
  void mvcControllerScopedBuild(MvcControllerCollection collection);
}
