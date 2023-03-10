part of './flutter_mvc.dart';

/// 状态范围
class MvcStateScope<TControllerType extends MvcController> extends Widget {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);
  final Widget Function(MvcWidgetStateProvider state) builder;
  final Widget? child;

  /// 该状态范围使用的状态来源
  ///
  /// 如果不指定，则使用离当前元素最近的[TControllerType]
  final MvcStateProvider? stateProvider;
  @override
  Element createElement() => MvcStateScopeElement<TControllerType>(this);
}

/// 状态范围[Element]
class MvcStateScopeElement<TControllerType extends MvcController> extends ComponentElement {
  MvcStateScopeElement(super.widget);
  MvcStateProvider? _stateProvider;
  Set<MvcStateValue>? _dependencies;
  bool _firstBuild = true;
  late final MvcStateProviderSession _sessionState = MvcStateProviderSession(this, _stateProvider!, child: (widget as MvcStateScope<TControllerType>?)?.child);

  @override
  void update(covariant Widget newWidget) {
    super.update(newWidget);
    var stateProvider = (widget as MvcStateScope<TControllerType>?)?.stateProvider;
    if (stateProvider != null && stateProvider != _stateProvider) {
      _stateProvider = stateProvider;
    }
    markNeedsBuild();
    rebuild();
  }

  @override
  void rebuild({bool force = false}) {
    if (_firstBuild) {
      var stateProvider = (widget as MvcStateScope<TControllerType>?)?.stateProvider ?? Mvc.get<TControllerType>(context: this);
      assert(stateProvider != null, "[MvcStateScope]无法从当前上下文获取[MvcStateScope]");
      _stateProvider = stateProvider!;
      _firstBuild = false;
    }
    super.rebuild();
  }

  @override
  Widget build() {
    _sessionState.startSession();
    var buildWidget = (widget as MvcStateScope<TControllerType>).builder(_sessionState);
    var stateValues = _sessionState.doneSession();
    _updateDependentStates(stateValues);
    return buildWidget;
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

/// 状态提供会话
///
/// 这会记录一次会话中获取过的所有状态
class MvcStateProviderSession extends MvcWidgetStateProvider {
  MvcStateProviderSession(this.context, this.stateProvider, {this.child});

  /// 状态提供者
  final MvcStateProvider stateProvider;
  @override
  final BuildContext context;

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
    var value = stateProvider.getStateValue<T>(key: key);
    if (value != null) {
      _sessionStates.add(value);
    }
    return value;
  }

  @override
  MvcWidgetStateProvider? part<T extends MvcStateProvider>() {
    if (stateProvider is MvcHasPartStateProvider) {
      var part = (stateProvider as MvcHasPartStateProvider).getStatePart<T>();
      if (part != null) {
        var partSession = MvcStateProviderSession(context, part, child: child);
        _parts.add(partSession);
        return partSession;
      }
    }
    return null;
  }

  @override
  Widget? child;
}
