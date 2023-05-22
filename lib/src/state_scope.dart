part of './flutter_mvc.dart';

/// 状态范围
class MvcStateScope<TControllerType extends MvcController> extends MvcStatefulWidget<TControllerType> {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);
  final Widget Function(MvcStateContext state) builder;
  final Widget? child;

  /// 该状态范围使用的状态来源
  ///
  /// 如果不指定，则从当前[TControllerType]服务范围获取[MvcStateProvider]
  final MvcStateProvider? stateProvider;

  @override
  MvcWidgetState<MvcController, MvcStatefulWidget<MvcController>> createState() => _MvcStateScopeState();
}

class _MvcStateScopeState<TControllerType extends MvcController> extends MvcWidgetState<TControllerType, MvcStateScope<TControllerType>> {
  Set<MvcStateValue>? _dependencies;

  @override
  void initService(ServiceCollection collection) {
    super.initService(collection);
    if (widget.stateProvider != null) {
      collection.addSingleton((serviceProvider) => widget.stateProvider!);
    }
  }

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
        element.removeListener(update);
      }
    }
    for (var element in addListenerDependentStates) {
      element.addListener(update);
    }
    _dependencies = dependentStates;
  }
}

/// 状态提供会话
///
/// 这会记录一次会话中获取过的所有状态
class MvcStateProviderSession extends MvcStateContext {
  MvcStateProviderSession(this.context, this.provider, {this.child});
  final Set<MvcStateValue> _states = {};

  @override
  final MvcStateProvider provider;

  @override
  final BuildContext context;

  @override
  final Widget? child;

  void start() => _states.clear();
  Set<MvcStateValue> done() => _states;
}
