part of './flutter_mvc.dart';

/// 状态范围
class MvcStateScope<TControllerType extends MvcController> extends MvcStatefulWidget<TControllerType> {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);
  final Widget Function(MvcWidgetStateProvider state) builder;
  final Widget? child;

  /// 该状态范围使用的状态来源
  ///
  /// 如果不指定，则使用离当前元素最近的[TControllerType]
  final MvcStateProvider? stateProvider;

  @override
  MvcWidgetState createState() => _MvcStateScopeState();
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

  void _updateDependentStates(Set<MvcStateValue> dependentStates) {
    Set<MvcStateValue> addListenerDependentStates = {...dependentStates};
    for (var element in _dependencies ?? <MvcStateValue>{}) {
      if (addListenerDependentStates.contains(element)) {
        addListenerDependentStates.remove(element);
      } else {
        element.removeListener(() => setState(() {}));
      }
    }
    for (var element in addListenerDependentStates) {
      element.addListener(() => setState(() {}));
    }
    _dependencies = dependentStates;
  }
}

/// 状态提供会话
///
/// 这会记录一次会话中获取过的所有状态
class MvcStateProviderSession extends MvcWidgetStateProvider {
  MvcStateProviderSession(this.context, this.stateProvider, {this.child});
  late final Set<MvcStateValue> _states = {};

  /// 状态提供者
  final MvcStateProvider stateProvider;
  @override
  final BuildContext context;

  void start() => _states.clear();
  Set<MvcStateValue> done() => _states;

  @override
  MvcStateValue<T>? getValue<T>({Object? key}) {
    var value = stateProvider.getStateValue<T>(key: key);
    if (value != null) {
      _states.add(value);
    }
    return value;
  }

  @override
  Widget? child;
}
