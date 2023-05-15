part of './flutter_mvc.dart';

/// Controller
abstract class MvcController<TModelType> extends ChangeNotifier with MvcStateProviderMixin, MvcControllerContextMixin, DependencyInjectionService {
  MvcElement? _element;

  @override
  MvcContext get context {
    assert(_element != null, "Controller has not been initialized");
    return _element!;
  }

  /// 获取model
  ///
  /// model同样保存在状态中，如果视图被外部更新时，将获取到不同的model
  /// 同样[MvcWidgetStateProvider]也可以使用[TModelType]获得model
  TModelType get model => getState<TModelType>()!;

  /// 初始化
  @mustCallSuper
  void init() {
    getService<MvcControllerPartManager>().init();
  }

  void activate() {}
  void _activateForElement(MvcElement element) {
    if (element == _element) {
      activate();
    }
  }

  void deactivate() {}
  void _deactivateForElement(MvcElement element) {
    assert(element._controller == this);
    if (element == _element) {
      deactivate();
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

  /// 获取[MvcControllerPart]
  T? getPart<T extends MvcControllerPart>() => getService<MvcControllerPartManager>().getPart<T>();

  /// 更新，将会触发View重建
  void update() => notifyListeners();

  /// 返回视图
  MvcView view(TModelType model);

  /// build part
  void buildPart(MvcControllerPartCollection collection) {}

  /// build当前Controler的服务
  void buildScopedService(MvcServiceCollection collection) {}
}

/// 代理Controller，Model为一个Widget，在View中将只会返回Model
///
/// 这在只有逻辑的Controller时使用，它仍然会在Element树中占据一个节点
class MvcProxyController extends MvcController<Widget> {
  @override
  MvcView view(Widget model) => MvcViewBuilder<MvcProxyController, Widget>((ctx) => model);
}
