part of './flutter_mvc.dart';

abstract class MvcController<TModelType> extends ChangeNotifier {
  final Map<MvcStateKey, MvcStateValue> _internalState = HashMap<MvcStateKey, MvcStateValue>();
  final Map<MvcStateKey, MvcStateValue> _globalState = HashMap<MvcStateKey, MvcStateValue>();
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
    for (var element in _globalState.keys) {
      MvcOwner.sharedOwner._globalState.remove(element);
    }
  }

  MvcStateValue<T> _initState<T>(MvcStateKey stateKey, MvcStateValue<T> stateValue) {
    assert(_internalState.containsKey(stateKey) == false, "创建了重复的状态类型,你可以使用key区分状态");
    _internalState[stateKey] = stateValue;
    if (stateValue.global) {
      assert(MvcOwner.sharedOwner._globalState.containsKey(stateKey) == false, "创建了重复的全局状态类型,你可以使用key区分状态");
      MvcOwner.sharedOwner._globalState[stateKey] = stateValue;
      _globalState[stateKey] = stateValue;
    }
    return stateValue;
  }

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// [global]是否设置为全局状态
  /// [forChild]是否将状态共享给子级
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key, bool global = false, bool forChild = true}) {
    var stateKey = MvcStateKey(stateType: T, key: key);
    var stateValue = MvcStateValue<T>(state, controller: this, global: global, forChild: forChild);
    return _initState<T>(stateKey, stateValue);
  }

  /// 初始化状态,如果状态存在直接返回状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// [global]是否设置为全局状态
  /// [forChild]是否将状态共享给子级
  /// [fromParent]查找状态是否存在时，是否从父级查找
  MvcStateValue<T> initStateIfNeed<T>(T Function() state, {Object? key, bool global = false, bool forChild = true, bool fromParent = false}) {
    var exist = getStateValue<T>(key: key, fromParent: fromParent);
    if (exist != null) return exist;
    return initState<T>(state(), key: key, global: global, forChild: forChild);
  }

  /// 更新状态
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T>? state)? updater, Object? key}) {
    var s = getStateValue<T>(key: key);
    updater?.call(s);
    s?.update();
    return s;
  }

  /// 使用指定值更新状态，如果状态不存在则初始化状态
  MvcStateValue<T> updateStateInitIfNeed<T>(T state, {Object? key}) {
    var s = getStateValue<T>(key: key);
    s ??= initState<T>(state, key: key);
    s.update();
    return s;
  }

  /// 链接状态到当前Controller,如果获取状态失败则返回null
  /// 如果被链接的状态发生更新，则这个状态也将更新
  /// 这个操作相当于[transformState]不做任何转换
  ///
  /// [T]要链接状态的类型
  /// [key]要链接状态的key
  /// [linkedToKey]链接之后的key
  /// [global]链接之后是否设置为全局状态
  /// [forChild]是否将链接之后的状态共享给子级
  MvcStateValue<T>? linkedState<T>({Object? key, Object? linkedToKey, bool global = false, bool forChild = true}) => transformState<T, T>((e) => e, key: key, transformToKey: linkedToKey, global: global, forChild: forChild);

  /// 转换状态到当前Controller,如果获取状态失败则返回null
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// 将指定状态转换一份
  /// [T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [key]要转换状态的key
  /// [transformToKey]转换之后的key
  /// [global]是否设置为全局状态
  /// [forChild]是否将状态共享给子级
  MvcStateValue<T>? transformState<T, E>(T Function(E state) transformer, {Object? key, Object? transformToKey, bool global = false, bool forChild = true}) {
    var state = getStateValue<E>(key: key);
    if (state != null) {
      var stateKey = MvcStateKey(stateType: T, key: transformToKey);
      var stateValue = MvcStateValueTransformer<T, E>(transformer(state.value), state, transformer, controller: this, global: global, forChild: forChild);
      return _initState<T>(stateKey, stateValue);
    }
    return null;
  }

  /// 与[transformState]类似，但是转换方法为异步，被转换的状态更新时，首先经过异步方法，异步方法结束后更新状态
  MvcStateValue<T>? asyncTransformState<T, E>(T initialValue, Future<T> Function(E state) transformer, {Object? key, Object? transformToKey, bool global = false, bool forChild = true}) {
    var state = getStateValue<E>(key: key);
    if (state != null) {
      var stateKey = MvcStateKey(stateType: T, key: key);
      var stateValue = MvcStateValueTransformer<T, E>(initialValue, state, transformer, controller: this, global: global, forChild: forChild);
      return _initState<T>(stateKey, stateValue);
    }
    return null;
  }

  /// 获取状态值
  MvcStateValue<T>? _getStateValue<T>({Object? key, bool fromParent = true, MvcController? originController}) {
    var stateValue = _internalState[MvcStateKey(stateType: T, key: key)] as MvcStateValue<T>?;
    if (stateValue == null) {
      if (fromParent) {
        var p = parent();
        var result = p?._getStateValue<T>(key: key, originController: originController ?? this);
        if (result?.forChild == true || result?.global == true) {
          return result;
        }
      }
      return MvcOwner.sharedOwner.getGlobalStateValue<T>(key: key);
    }
    return stateValue;
  }

  /// 获取状态值
  MvcStateValue<T>? getStateValue<T>({Object? key, bool fromParent = true}) => _getStateValue(key: key, fromParent: fromParent);

  /// 获取状态
  T? getState<T>({Object? key, bool fromParent = true}) => getStateValue<T>(key: key, fromParent: fromParent)?.value;

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
