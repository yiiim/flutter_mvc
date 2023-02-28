part of './flutter_mvc.dart';

abstract class MvcControllerPart<TControllerType extends MvcController> with MvcControllerStateMixin {
  TControllerType? _controller;
  TControllerType get controller {
    assert(_controller != null, "");
    return _controller!;
  }

  @override
  late final MvcControllerState _state = MvcControllerState(controller, controllerPart: this);

  @override
  MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.internal}) {
    return super.initState(state, key: key, accessibility: accessibility);
  }

  void init() {}
}
