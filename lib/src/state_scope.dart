part of './flutter_mvc.dart';

abstract class MvcStateScopeContext extends MvcStateContext {
  Widget? get child;
}

/// 状态范围
class MvcStateScope<TControllerType extends MvcController> extends MvcStatefulWidget<TControllerType> {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);
  final Widget Function(MvcStateScopeContext state) builder;
  final Widget? child;

  /// 该状态范围使用的状态来源
  ///
  /// 如果不指定，则从当前[TControllerType]服务范围获取[MvcStateProvider]
  final MvcStateProvider? stateProvider;

  @override
  MvcWidgetState<TControllerType, MvcStatefulWidget<TControllerType>> createState() => _MvcStateScopeState();
}

class _MvcStateScopeState<TControllerType extends MvcController> extends MvcWidgetState<TControllerType, MvcStateScope<TControllerType>> {
  Set<MvcStateValue>? _dependencies;

  @override
  Widget build(BuildContext context) {
    var stateProvider = getService<MvcStateProvider>();
    var session = MvcStateProviderSession(context, stateProvider, child: widget.child);
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _updateDependentStates(session.done());
      },
    );
    session.start();
    return widget.builder(session);
  }

  @override
  void deactivate() {
    super.deactivate();
    final dependencies = _dependencies ?? {};
    for (var element in dependencies) {
      element.removeListener(_update);
    }
  }

  @override
  void activate() {
    super.activate();
    final dependencies = _dependencies ?? {};
    for (var element in dependencies) {
      element.addListener(_update);
    }
  }

  void _updateDependentStates(Set<MvcStateValue> dependentStates) {
    Set<MvcStateValue> addListenerDependentStates = {...dependentStates};
    for (var element in _dependencies ?? <MvcStateValue>{}) {
      if (addListenerDependentStates.contains(element)) {
        addListenerDependentStates.remove(element);
      } else {
        element.removeListener(_update);
      }
    }
    for (var element in addListenerDependentStates) {
      element.addListener(_update);
    }
    _dependencies = dependentStates;
  }

  void _update() {
    setState(() {});
  }
}

/// 状态提供会话
///
/// 这会记录一次会话中获取过的所有状态
class MvcStateProviderSession extends MvcStateScopeContext {
  MvcStateProviderSession(this.context, this.provider, {this.child});
  final Set<MvcStateValue> _states = {};

  final MvcStateProvider provider;
  @override
  final Widget? child;
  @override
  final BuildContext context;

  /// 获取状态值
  ///
  /// [key] 状态key
  @override
  MvcStateValue<T>? getValue<T>({Object? key}) {
    var value = provider.getStateValue<T>(key: key);
    if (value != null) _states.add(value);
    return value;
  }

  void start() => _states.clear();
  Set<MvcStateValue> done() => _states;
}
