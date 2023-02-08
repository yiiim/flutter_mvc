part of './flutter_mvc.dart';

abstract class MvcController<TModelType> extends ChangeNotifier {
  final Map<MvcStateKey, MvcStateValue> _internalState = HashMap<MvcStateKey, MvcStateValue>();
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
    }
    dispose();
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

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key}) {
    var stateKey = MvcStateKey(stateType: T, key: key);
    assert(_internalState.containsKey(stateKey) == false, "创建了重复的状态类型,你可以使用key区分状态");
    var stateValue = MvcStateValue<T>(state, controller: this);
    _internalState[stateKey] = stateValue;
    return stateValue;
  }

  /// 更新状态
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T>? state)? updater, Object? key}) {
    var s = getStateValue<T>(key: key);
    updater?.call(s);
    s?.update();
    return s;
  }

  /// 获取状态值
  MvcStateValue<T>? getStateValue<T>({Object? key, bool fromParent = true}) {
    var stateValue = _internalState[MvcStateKey(stateType: T, key: key)] as MvcStateValue<T>?;
    if (stateValue == null && fromParent) {
      var p = parent();
      assert(() {
        if (p != null) {
          debugPrint("Warning!!!当前Controller($runtimeType)未获取到状态$T,将尝试从父级获取");
        } else {
          debugPrint("Warning!!!当前Controller($runtimeType)未获取到状态$T");
        }
        return true;
      }());
      return p?.getStateValue<T>(key: key);
    }
    return stateValue;
  }

  /// 获取状态
  T? getState<T>({Object? key, bool fromParent = true}) => getStateValue<T>(key: key, fromParent: fromParent)?.value;

  /// 返回视图
  MvcView view(MvcContext context);
}

class MvcProxyController extends MvcController<Widget> {
  @override
  MvcView view(MvcContext context) => MvcViewBuilder<MvcProxyController, Widget>((ctx) => ctx.model);
}
