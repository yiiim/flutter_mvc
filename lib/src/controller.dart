part of './flutter_mvc.dart';

/// Controller
abstract class MvcController<TModelType> extends ChangeNotifier with MvcControllerContextMixin, DependencyInjectionService, MvcControllerPartMixin, MvcStateProviderMixin, MvcControllerStateProvider {
  MvcElement? _element;

  @override
  MvcContext get context {
    assert(_element != null, "Controller has not been initialized");
    return _element!;
  }

  /// 获取model
  ///
  /// model同样保存在状态中，如果视图被外部更新时，将获取到不同的model
  /// 同样[MvcStateContext]也可以使用[TModelType]获得model
  TModelType get model => getState<TModelType>()!;

  /// 初始化
  @override
  @mustCallSuper
  @protected
  void init() {
    super.init();
  }

  @mustCallSuper
  @protected
  void initService(MvcServiceCollection collection) {}
  @mustCallSuper
  @protected
  void activate() {}
  @mustCallSuper
  @protected
  void deactivate() {}

  bool _debugTypesAreRight(model) => model is TModelType;

  /// 返回视图
  MvcView view();

  /// 更新，将会触发View重建
  void update() => notifyListeners();
}

/// 代理Controller，Model为一个Widget，在View中将只会返回Model
///
/// 这在只有逻辑的Controller时使用，它仍然会在Element树中占据一个节点
class MvcProxyController extends MvcController<Widget> {
  @override
  MvcView view() => MvcViewBuilder<MvcProxyController, Widget>((ctx) => model);
}
