part of './flutter_mvc.dart';

/// Controller
abstract class MvcController<TModelType> extends ChangeNotifier with MvcControllerStateMixin, MvcControllerContextMixin {
  MvcElement? _element;

  @override
  MvcContext get context {
    assert(_element != null, "请在Controller init后使用context");
    return _element!;
  }

  @override
  late final MvcControllerState _state = MvcControllerState(this);

  /// 获取model
  ///
  /// model同样保存在状态中，如果视图被外部更新时，将获取到不同的model
  /// 同样[MvcWidgetStateProvider]也可以使用[TModelType]获得model
  TModelType get model => getState<TModelType>()!;

  /// 初始化
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

  @override
  void dispose() {
    super.dispose();
    _state.dispose();
  }

  late final Map<Type, MvcControllerPart> _typePartsMap = {};
  late final Map<MvcControllerPart, Type> _partsTypeMap = {};

  /// 注册[MvcControllerPart]，需要指定[TPartType]的类型
  void registerPart<TPartType extends MvcControllerPart>(TPartType part) {
    assert(TPartType != MvcControllerPart, "必须指定Part的类型");
    assert(_typePartsMap[TPartType] == null, "不能注册相同类型的多个Part");
    assert(_partsTypeMap[part] == null, "同一Part实例不能注册多次");
    part._controller = this;
    part.init();
    _typePartsMap[TPartType] = part;
    _partsTypeMap[part] = TPartType;
  }

  /// 获取指定类型的[MvcControllerPart]，指定的类型必须和[registerPart]方法注册时的类型一致
  ///
  /// [tryGetFromParent]是否尝试父级获取，默认为true
  TPartType? part<TPartType extends MvcControllerPart>({bool tryGetFromParent = true}) {
    var part = (_typePartsMap[TPartType] as TPartType?);
    if (part == null && tryGetFromParent) part = parent()?.part<TPartType>();
    return part;
  }

  /// 更新，将会触发View重建
  void update() => notifyListeners();

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
