part of './flutter_mvc.dart';

enum _MvcControllerStateAccessibility {
  global,
  public,
  private,
}

class _MvcControllerStateValue<T> {
  _MvcControllerStateValue({required this.value, this.accessibility = _MvcControllerStateAccessibility.public});
  final MvcStateValue<T> value;
  final _MvcControllerStateAccessibility accessibility;
}

/// [MvcControllerStateSession]可以获取[MvcController]在一次会话中获取过的状态
class MvcControllerStateSession {
  MvcControllerStateSession(this._controller);
  final List<MvcStateValue> _states = [];
  final MvcController _controller;
  void _putStateValue(MvcStateValue state) => _states.add(state);

  void start() => _controller._sessions.add(this);
  List<MvcStateValue> done() {
    _controller._sessions.remove(this);
    var result = [..._states];
    _states.clear();
    return result;
  }
}

abstract class MvcController<TModelType> extends ChangeNotifier {
  final Map<MvcStateKey, _MvcControllerStateValue> _internalState = HashMap<MvcStateKey, _MvcControllerStateValue>();
  final List<MvcControllerStateSession> _sessions = [];
  MvcElement? _element;
  MvcContext get context {
    assert(_element != null, "请在Controller init后使用context");
    return _element!;
  }

  /// 获取model
  ///
  /// model同样保存在状态中，如果视图被外部更新时，将获取到不同的model
  /// 同样[MvcState]也可以使用[TModelType]获得model
  TModelType get model => getState<TModelType>()!;

  void init() {}
  void activate() {}
  void _activateForElement(MvcElement element) {
    if (element == _element) {
      activate();
    }
  }

  void _initForElement(MvcElement element) {
    assert(element._controller == this);
    if (_element == null) {
      _element = element;
      init();
    } else {}
  }

  void _disposeForElement(MvcElement element) {
    assert(element._controller == this);
    if (element == _element) {
      _element = null;
      dispose();
    }
  }

  /// 从父级查找指定类型的Controller
  T? parent<T extends MvcController>() => _element!.parent<T>();

  /// 在直接子级查找指定类型的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? child<T extends MvcController>({bool sort = false}) => _element!.child<T>(sort: sort);

  /// 从所有子级中查找指定类型的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? find<T extends MvcController>({bool sort = false}) => _element!.find<T>(sort: sort);

  /// 在同级中查找前面的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? previousSibling<T extends MvcController>({bool sort = false}) => _element!.previousSibling<T>(sort: sort);

  /// 在同级中查找后面的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? nextSibling<T extends MvcController>({bool sort = false}) => _element!.nextSibling<T>(sort: sort);

  /// 在同级中查找Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  /// [includeSelf]表示是否包含自己本身
  T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) => _element!.sibling<T>(sort: sort);

  /// 向前查找，表示查找同级前面的和父级，相当于[previousSibling]??[parent]
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? forward<T extends MvcController>({bool sort = false}) => _element!.forward<T>(sort: sort);

  /// 向后查找，表示查找同级后面的和子级，相当于[nextSibling]??[find]
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? backward<T extends MvcController>({bool sort = false}) => _element!.backward<T>(sort: sort);

  /// 更新View，将会触发View重建
  void update() => notifyListeners();

  @override
  void dispose() {
    super.dispose();
    for (var element in _internalState.keys) {
      if (_internalState[element]!.accessibility == _MvcControllerStateAccessibility.global) {
        MvcOwner.sharedOwner._globalState.remove(element);
      }
    }
  }

  MvcStateValue<T> _initState<T>(MvcStateKey stateKey, MvcStateValue<T> stateValue, {bool global = false, bool private = false}) {
    assert(_internalState.containsKey(stateKey) == false, "创建了重复的状态类型,你可以使用key区分状态");
    assert(!global || !private, "global 和 private不能同时为true");
    assert(!global || MvcOwner.sharedOwner._globalState.containsKey(stateKey) == false, "创建了重复的全局状态类型,你可以使用key区分状态");

    _MvcControllerStateAccessibility accessibility = _MvcControllerStateAccessibility.public;
    if (global) {
      accessibility = _MvcControllerStateAccessibility.global;
      MvcOwner.sharedOwner._globalState[stateKey] = stateValue;
    } else if (private) {
      accessibility = _MvcControllerStateAccessibility.private;
    }
    _internalState[stateKey] = _MvcControllerStateValue<T>(value: stateValue, accessibility: accessibility);
    return stateValue;
  }

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// [global]是否设置为全局状态
  /// [private]是否是私有状态
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key, bool global = false, bool private = false}) {
    var stateKey = MvcStateKey(stateType: T, key: key);
    var stateValue = MvcStateValue<T>(state, controller: this);
    return _initState<T>(stateKey, stateValue, global: global, private: private);
  }

  /// 更新状态，如果状态不存在则返回null
  ///
  /// [updater]更新状态的方法，即使没有[updater]状态也会更新
  /// [key]要更新状态的key
  /// [onlySelf]是否仅在当前Controller获取
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key, bool onlySelf = false}) {
    var s = getStateValue<T>(key: key);
    if (s != null) updater?.call(s);
    s?.update();
    return s;
  }

  /// 使用指定值更新状态，如果状态不存在则初始化状态
  MvcStateValue<T> updateStateInitIfNeed<T>(T state, {Object? key, bool onlySelf = false}) {
    var s = getStateValue<T>(key: key);
    s ??= initState<T>(state, key: key);
    s.update();
    return s;
  }

  /// 初始化一个链接状态,如果没有获取目标状态则返回null
  /// 链接状态的值和被连接状态保持一致，这其实相当于一个拷贝操作
  /// 如果被链接的状态发生更新，则这个状态也将更新
  /// 这个操作相当于[initTransformState]不做任何转换
  ///
  /// [T]要链接状态的类型
  /// [key]要链接状态的key
  /// [onlySelf]获取要链接的状态时，是否仅在当前状态获取
  /// [linkedToKey]链接之后的key
  /// [global]链接之后是否设置为全局状态
  /// [private]是否将链接之后的状态共享给子级
  MvcStateValue<T>? initLinkedState<T>({Object? key, bool onlySelf = false, Object? linkedToKey, bool global = false, bool private = false}) => initTransformState<T, T>((e) => e, key: key, onlySelf: onlySelf, transformToKey: linkedToKey, global: global, private: private);

  /// 初始化一个转换状态,如果没有获取到目标状态则返回null
  /// 将指定状态转换为新的状态
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// [T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [key]被转换状态的key
  /// [onlySelf]获取被装换状态时，是否仅在当前状态获取
  /// [transformToKey]转换之后的key
  /// [global]是否设置为全局状态
  /// [private]是否将状态共享给子级
  MvcStateValue<T>? initTransformState<T, E>(T Function(E state) transformer, {Object? key, bool onlySelf = false, Object? transformToKey, bool global = false, bool private = false}) {
    var state = getStateValue<E>(key: key, onlySelf: onlySelf);
    if (state != null) {
      var stateKey = MvcStateKey(stateType: T, key: transformToKey);
      var stateValue = MvcStateValueTransformer<T, E>(transformer(state.value), state, transformer, controller: this);
      return _initState<T>(stateKey, stateValue, global: global, private: private);
    }
    return null;
  }

  /// 与[initTransformState]类似，但是转换方法为异步，被转换的状态更新时，首先经过异步方法，异步方法结束后更新状态
  Future<MvcStateValue<T>?> initAsyncTransformState<T, E>(Future<T> Function(E state) transformer, {Object? key, bool onlySelf = false, Object? transformToKey, bool global = false, bool private = false}) async {
    var state = getStateValue<E>(key: key, onlySelf: onlySelf);
    if (state != null) {
      var stateKey = MvcStateKey(stateType: T, key: transformToKey);
      var stateValue = MvcStateValueTransformer<T, E>(await transformer(state.value), state, transformer, controller: this);
      return _initState<T>(stateKey, stateValue, global: global, private: private);
    }
    return null;
  }

  /// 初始化一个依赖状态
  ///
  /// [builder] 状态值构建者，在构建过程中使用当前Controller获取过的任何状态都将成为该状态的依赖状态，依赖状态更新时，该状态更新
  /// [key]状态的key
  /// [global]是否设置为全局状态
  /// [private]是否将状态共享给子级
  MvcStateValue<T> initDependentState<T>(T Function() builder, {Object? key, bool global = false, bool private = false}) {
    var stateKey = MvcStateKey(stateType: T, key: key);
    var session = MvcControllerStateSession(this);
    try {
      session.start();
      var value = builder();
      var states = session.done();
      MvcDependentStateValueBuilder<T>? stateValue;
      stateValue = MvcDependentStateValueBuilder<T>(
        value,
        states.toSet(),
        builder: () {
          var session = MvcControllerStateSession(this);
          try {
            session.start();
            var value = builder();
            var states = session.done();
            stateValue?.updateDependentStates(states.toSet());
            return value;
          } catch (_) {
            rethrow;
          } finally {
            session.done();
          }
        },
        controller: this,
      );
      return _initState(stateKey, stateValue, global: global, private: private);
    } catch (_) {
      rethrow;
    } finally {
      session.done();
    }
  }

  /// 与[initDependentState]类似，但是[builder]方法为异步，被转换的状态更新时，首先经过异步方法，异步方法结束后更新状态
  Future<MvcStateValue<T>> initAsyncDependentState<T>(Future<T> Function() builder, {Object? key, bool global = false, bool private = false}) async {
    var stateKey = MvcStateKey(stateType: T, key: key);
    var session = MvcControllerStateSession(this);
    try {
      session.start();
      var value = await builder();
      var states = session.done();
      MvcDependentStateValueBuilder<T>? stateValue;
      stateValue = MvcDependentStateValueBuilder<T>(
        value,
        states.toSet(),
        builder: () async {
          var session = MvcControllerStateSession(this);
          try {
            session.start();
            var value = await builder();
            var states = session.done();
            stateValue?.updateDependentStates(states.toSet());
            return value;
          } catch (_) {
            rethrow;
          } finally {
            session.done();
          }
        },
        controller: this,
      );
      return _initState(stateKey, stateValue, global: global, private: private);
    } catch (_) {
      rethrow;
    } finally {
      session.done();
    }
  }

  /// 获取[_MvcControllerStateValue]状态值
  _MvcControllerStateValue<T>? _getControllerStateValue<T>({Object? key, bool onlySelf = false, MvcController? originController}) {
    var stateValue = _internalState[MvcStateKey(stateType: T, key: key)] as _MvcControllerStateValue<T>?;
    if (stateValue != null) {
      if (stateValue.accessibility == _MvcControllerStateAccessibility.global) return stateValue;
      if (stateValue.accessibility == _MvcControllerStateAccessibility.private && (originController == null || originController == this)) return stateValue;
      if (stateValue.accessibility == _MvcControllerStateAccessibility.public) return stateValue;
    }
    if (!onlySelf) {
      return parent()?._getControllerStateValue<T>(key: key, originController: originController ?? this);
    }
    return null;
  }

  /// 获取状态值
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller获取
  MvcStateValue<T>? _getStateValue<T>({Object? key, bool onlySelf = false}) {
    var value = _getControllerStateValue<T>(key: key, onlySelf: onlySelf, originController: this)?.value ?? MvcOwner.sharedOwner.getGlobalStateValue<T>(key: key);
    if (value != null) {
      for (var element in _sessions) {
        element._putStateValue(value);
      }
    }
    return value;
  }

  /// 获取状态,如果状态不存在则重新初始化状态并返回
  ///
  /// [state]如果需要初始化状态，状态的创建者
  /// [onlySelf]获取状态时否仅在当前Controller获取
  /// [key]状态的key
  /// [global]如果需要初始化状态，是否设置为全局状态
  /// [private]如果需要初始化状态，是否设置为私有状态
  MvcStateValue<T> getOrInitStateValue<T>(T Function() state, {Object? key, bool onlySelf = false, bool global = false, bool private = false}) {
    var exist = getStateValue<T>(key: key, onlySelf: onlySelf);
    if (exist != null) return exist;
    return initState<T>(state(), key: key, global: global, private: private);
  }

  /// 获取状态值
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller获取
  MvcStateValue<T>? getStateValue<T>({Object? key, bool onlySelf = false}) => _getStateValue(key: key, onlySelf: onlySelf);

  /// 获取状态
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller获取
  T? getState<T>({Object? key, bool onlySelf = false}) => getStateValue<T>(key: key, onlySelf: onlySelf)?.value;

  /// 返回视图
  MvcView view(TModelType model);
}

/// 代理Controller，Model为一个Widget，在View中将只会返回Model
///
/// 这在只有逻辑的Controller时使用，它仍然会在Element树中占据一个节点
class MvcProxyController extends MvcController<Widget> {
  @override
  MvcView view(Widget model) => MvcViewBuilder<MvcProxyController, Widget>((ctx) => model);
}
