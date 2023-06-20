part of './flutter_mvc.dart';

abstract class MvcControllerPartCollection {
  void addPart<TPartType extends MvcControllerPart>(TPartType Function() partCreate);
}

abstract class MvcControllerPart<TControllerType extends MvcController> with MvcStateProviderMixin, DependencyInjectionService {
  TControllerType get controller => getService<MvcController>() as TControllerType;
  void init() {}
}
