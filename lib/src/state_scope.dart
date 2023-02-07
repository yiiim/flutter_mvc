part of './flutter_mvc.dart';

class MvcStateScope<TControllerType extends MvcController> extends Widget {
  const MvcStateScope(this.builder, {this.controller, Key? key}) : super(key: key);
  final Widget Function(MvcState<TControllerType> state) builder;
  final TControllerType? controller;
  @override
  Element createElement() => MvcStateScopeElement<TControllerType>(this);
}

class MvcStateScopeElement<TControllerType extends MvcController> extends ComponentElement implements MvcState<TControllerType> {
  MvcStateScopeElement(super.widget);
  TControllerType? _controller;
  bool _firstBuild = true;
  Set<MvcStateValue>? _dependencies;
  @override
  void update(covariant Widget newWidget) {
    super.update(newWidget);
    var controller = (widget as MvcStateScope<TControllerType>?)?.controller;
    if (controller != null && controller != _controller) {
      _controller = controller;
    }
  }

  @override
  void rebuild() {
    if (_firstBuild) {
      _controller = (widget as MvcStateScope<TControllerType>?)?.controller ?? Mvc.get<TControllerType>(context: this);
      _firstBuild = false;
    }
    super.rebuild();
  }

  @override
  Widget build() {
    return (widget as MvcStateScope<TControllerType>).builder(this);
  }

  @override
  void activate() {
    _dependencies?.clear();
    super.activate();
  }

  @override
  void deactivate() {
    if (_dependencies != null && _dependencies!.isNotEmpty) {
      for (var element in _dependencies!) {
        element.removeListener(markNeedsBuild);
      }
    }
    super.deactivate();
  }

  @override
  T? get<T>({String? name}) => getValue<T>(name: name)?.value;
  @override
  MvcStateValue<T>? getValue<T>({String? name}) {
    var stateValue = controller.getStateValue<T>(name: name);
    if (stateValue != null && _dependencies?.contains(stateValue) != true) {
      stateValue.addListener(markNeedsBuild);
      _dependencies ??= HashSet<MvcStateValue>();
      _dependencies!.add(stateValue);
    }
    return stateValue;
  }

  @override
  BuildContext get context => this;

  @override
  TControllerType get controller {
    assert(_controller != null, "状态区域内无法获取Controller");
    return _controller!;
  }
}
