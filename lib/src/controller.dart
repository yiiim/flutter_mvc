part of './flutter_mvc.dart';

/// Controller
abstract class MvcController<TModelType> extends ChangeNotifier with MvcControllerContextMixin, DependencyInjectionService, MvcStateProviderMixin, MvcControllerStateProvider {
  MvcElement? _element;

  /// part管理器
  late final partManager = getService<MvcControllerPartManager>();

  /// 环境
  late final environment = getService<MvcControllerEnvironment>();

  @override
  MvcControllerEnvironmentStateProvider get environmentStateProvider => environment;
  @override
  MvcControllerPartStateProvider get partStateProvider => partManager;
  @override
  MvcContext get mvcContext {
    assert(_element != null, "Controller has not been initialized");
    return _element!;
  }

  BuildContext get context => mvcContext.buildContext;

  /// 获取model
  ///
  /// model同样保存在状态中，如果视图被外部更新时，将获取到不同的model
  /// 同样[MvcStateContext]也可以使用[TModelType]获得model
  TModelType get model => getState<TModelType>()!;

  /// 初始化
  @mustCallSuper
  @protected
  void init() {
    partManager.init();
  }

  /// 初始化Part
  @mustCallSuper
  @protected
  void initPart(MvcControllerPartCollection collection) {}

  /// 初始化Service
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

  /// 获取[MvcControllerPart]
  T? getPart<T extends MvcControllerPart>() => partManager.getPart<T>();

  /// 从Part中获取状态
  /// [T]状态类型
  /// [TPartType]Part的类型，如果是[MvcControllerPart]，则查找全部的Part，如果传入具体的类型则从指定类型的Part中获取状态
  MvcStateValue<T>? getPartStateValue<T, TPartType extends MvcControllerPart>({Object? key}) {
    if (TPartType == MvcControllerPart) {
      return partManager.getStateValue<T>(key: key);
    }
    return partManager.getPart<TPartType>()?.getStateValue<T>(key: key);
  }
}

/// 代理Controller，Model为一个Widget，在View中将只会返回Model
///
/// 这在只有逻辑的Controller时使用，它仍然会在Element树中占据一个节点
class MvcProxyController extends MvcController<Widget> {
  @override
  MvcView view() => MvcViewBuilder<MvcProxyController, Widget>((ctx) => model);
}
