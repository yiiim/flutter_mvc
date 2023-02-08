part of './flutter_mvc.dart';

/// 只是为了[MvcStateScopeElement]拿到不同[Widget]的Controller
abstract class _MvcStateScope<TControllerType extends MvcController> {
  TControllerType? get stateScopeController;
}

/// 状态范围
class MvcStateScope<TControllerType extends MvcController> extends Widget implements _MvcStateScope<TControllerType> {
  const MvcStateScope(this.builder, {this.controller, Key? key}) : super(key: key);
  final Widget Function(MvcState<TControllerType> state) builder;

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
  final Widget Function(MvcState<TControllerType> state, Widget? child) builder;
  final TControllerType? controller;
  final Widget? child;
  @override
  Element createElement() => MvcStateScopeElement<TControllerType>(this);

  @override
  TControllerType? get stateScopeController => controller;
}

class MvcStateScopeElement<TControllerType extends MvcController> extends ComponentElement implements MvcState<TControllerType> {
  MvcStateScopeElement(super.widget);
  TControllerType? _controller;
  bool _firstBuild = true;
  Set<MvcStateValue>? _dependencies;
  @override
  void update(covariant Widget newWidget) {
    super.update(newWidget);
    var controller = (widget as _MvcStateScope<TControllerType>?)?.stateScopeController;
    if (controller != null && controller != _controller) {
      _controller = controller;
    }
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
    if (widget is MvcStateScope<TControllerType>) return (widget as MvcStateScope<TControllerType>).builder(this);
    if (widget is MvcChildStateScope<TControllerType>) return (widget as MvcChildStateScope<TControllerType>).builder(this, (widget as MvcChildStateScope<TControllerType>).child);
    throw "unknow widget";
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
  T? get<T>({Object? key}) => getValue<T>(key: key)?.value;
  @override
  MvcStateValue<T>? getValue<T>({Object? key}) {
    var stateValue = controller.getStateValue<T>(key: key);
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
