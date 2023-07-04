part of './flutter_mvc.dart';

abstract class MvcControllerPartCollection {
  void addPart<TPartType extends MvcControllerPart>(TPartType Function() partCreate);
}

abstract class MvcControllerPart<TControllerType extends MvcController> with MvcStateProviderMixin, DependencyInjectionService {
  TControllerType get controller => getService<MvcController>() as TControllerType;
  void init() {}
}

mixin MvcControllerPartMixin on DependencyInjectionService {
  late final MvcControllerPartManager _partManager = getService<MvcControllerPartManager>();

  @mustCallSuper
  @protected
  void init() {
    _partManager.init();
  }

  /// 获取[MvcControllerPart]
  T? getPart<T extends MvcControllerPart>() => getService<MvcControllerPartManager>().getPart<T>();

  @mustCallSuper
  @protected
  void initPart(MvcControllerPartCollection collection) {}

  /// 从Part中获取状态
  /// [T]状态类型
  /// [TPartType]Part的类型，如果是[MvcControllerPart]，则查找全部的Part，如果传入具体的类型则从指定类型的Part中获取状态
  MvcStateValue<T>? getPartStateValue<T, TPartType extends MvcControllerPart>({Object? key}) {
    if (TPartType == MvcControllerPart) {
      return getService<MvcControllerPartManager>().getStateValue<T>(key: key);
    }
    return getService<MvcControllerPartManager>().getPart<TPartType>()?.getStateValue<T>(key: key);
  }
}
