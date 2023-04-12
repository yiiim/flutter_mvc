part of './flutter_mvc.dart';

abstract class MvcControllerPartCollection {
  void addPart<TPartType extends MvcControllerPart>(TPartType Function() partCreate);
}

abstract class MvcControllerPart<TControllerType extends MvcController> with MvcControllerStateMixin, DependencyInjectionService {
  @override
  late final MvcControllerState _state = MvcControllerState(controller, controllerPart: this);
  TControllerType get controller => getService<MvcController>() as TControllerType;
  void init() {}
}
