part of './flutter_mvc.dart';

/// 只是为了[MvcStateScopeElement]拿到不同[Widget]的Controller
abstract class _MvcStateScope<TControllerType extends MvcController> {
  TControllerType? get stateScopeController;
}

/// 状态范围
class MvcStateScope<TControllerType extends MvcController> extends Widget implements _MvcStateScope<TControllerType> {
  const MvcStateScope(this.builder, {this.controller, Key? key}) : super(key: key);
  final Widget Function(MvcWidgetStateProvider<TControllerType> state) builder;

  /// 该状态范围使用的状态来源
  ///
  /// 如果指定了controller，则使用该controller的状态
  /// 如果不指定，则使用离当前元素最近的[TControllerType]类型的controller的状态
  final TControllerType? controller;
  @override
  Element createElement() => MvcStateScopeElement<TControllerType>(this);

  @override
  TControllerType? get stateScopeController => controller;
}

/// 一个包含子级的状态范围
///
/// 在状态重建时[child]不会重建，这可以增加性能
class MvcChildStateScope<TControllerType extends MvcController> extends Widget implements _MvcStateScope<TControllerType> {
  const MvcChildStateScope(this.builder, {this.controller, this.child, super.key});
  final Widget Function(MvcWidgetStateProvider<TControllerType> state, Widget? child) builder;
  final TControllerType? controller;
  final Widget? child;
  @override
  Element createElement() => MvcStateScopeElement<TControllerType>(this);

  @override
  TControllerType? get stateScopeController => controller;
}

/// 状态提供会话
///
/// 这回记录一次会话中获取过的所有状态
class MvcStateProviderSession<TControllerType extends MvcController> extends MvcWidgetStateProvider<TControllerType> {
  MvcStateProviderSession(this.context, this.controller, this.state);

  final MvcStateProvider state;
  @override
  final BuildContext context;
  @override
  final TControllerType controller;

  late final List<MvcStateProviderSession> _parts = [];
  late final Set<MvcStateValue> _sessionStates = {};
  void startSession() {
    _parts.clear();
    _sessionStates.clear();
  }

  Set<MvcStateValue> doneSession() {
    return {..._sessionStates, ..._parts.map((e) => e._sessionStates).expand((element) => element)};
  }

  @override
  T? get<T>({Object? key}) => getValue<T>(key: key)?.value;
  @override
  MvcStateValue<T>? getValue<T>({Object? key}) {
    var value = state.getStateValue<T>(key: key);
    if (value != null) {
      _sessionStates.add(value);
    }
    return value;
  }

  @override
  MvcWidgetStateProvider? part<T extends MvcControllerPart>() {
    var part = controller.part<T>();
    if (part == null) return null;
    var partSession = MvcStateProviderSession(context, controller, part);
    _parts.add(partSession);
    return partSession;
  }
}

class MvcStateScopeElement<TControllerType extends MvcController> extends ComponentElement {
  MvcStateScopeElement(super.widget);
  TControllerType? _controller;
  bool _firstBuild = true;
  Set<MvcStateValue>? _dependencies;

  late final MvcStateProviderSession<TControllerType> _sessionState = MvcStateProviderSession<TControllerType>(this, _controller!, _controller!);

  @override
  void update(covariant Widget newWidget) {
    super.update(newWidget);
    var controller = (widget as _MvcStateScope<TControllerType>?)?.stateScopeController;
    if (controller != null && controller != _controller) {
      _controller = controller;
    }
    markNeedsBuild();
    rebuild();
  }

  @override
  void rebuild() {
    if (_firstBuild) {
      _controller = (widget as _MvcStateScope<TControllerType>?)?.stateScopeController ?? Mvc.get<TControllerType>(context: this);
      _firstBuild = false;
    }
    super.rebuild();
  }

  @override
  Widget build() {
    Widget? buildWidget;
    _sessionState.startSession();
    if (widget is MvcStateScope<TControllerType>) buildWidget = (widget as MvcStateScope<TControllerType>).builder(_sessionState);
    if (widget is MvcChildStateScope<TControllerType>) buildWidget = (widget as MvcChildStateScope<TControllerType>).builder(_sessionState, (widget as MvcChildStateScope<TControllerType>).child);
    if (buildWidget == null) "MvcStateScopeElement did get unknow widget";
    var stateValues = _sessionState.doneSession();
    _updateDependentStates(stateValues);
    return buildWidget!;
  }

  void _updateDependentStates(Set<MvcStateValue> dependentStates) {
    Set<MvcStateValue> addListenerDependentStates = {...dependentStates};
    for (var element in _dependencies ?? <MvcStateValue>{}) {
      if (addListenerDependentStates.contains(element)) {
        addListenerDependentStates.remove(element);
      } else {
        element.removeListener(markNeedsBuild);
      }
    }
    for (var element in addListenerDependentStates) {
      element.addListener(markNeedsBuild);
    }
    _dependencies = dependentStates;
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
}
