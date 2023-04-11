part of './flutter_mvc.dart';

abstract class MvcControllerPartCollection {
  void addPart<TPartType extends MvcControllerPart>(TPartType part);
}

abstract class MvcControllerPart<TControllerType extends MvcController> with MvcControllerStateMixin, DependencyInjectionService {
  TControllerType get controller => getService<MvcController>() as TControllerType;

  @override
  late final MvcControllerState _state = MvcControllerState(controller, controllerPart: this);

  @override
  MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.internal}) {
    assert(accessibility == MvcStateAccessibility.internal, "Part中仅可初始化访问级别为internal的状态");
    return super.initState(state, key: key, accessibility: MvcStateAccessibility.internal);
  }

  void init() {}
}
