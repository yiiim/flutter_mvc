part of './flutter_mvc.dart';

class _MvcControllerPartCollection extends ServiceCollection implements MvcControllerPartCollection {
  _MvcControllerPartCollection(this.manager);
  final MvcControllerPartManager manager;
  @override
  void addPart<TPartType extends MvcControllerPart<MvcController>>(TPartType Function() partCreate) {
    manager._partTypes.add(TPartType);
    addSingleton<TPartType>((serviceProvider) => partCreate());
  }
}

/// ControllerPart管理器
class MvcControllerPartManager with DependencyInjectionService implements MvcControllerPartStateProvider {
  late final List<Type> _partTypes = [];
  late final ServiceProvider _partProvider;
  void init() {
    for (var element in _partTypes) {
      (_partProvider.getByType(element) as MvcControllerPart).init();
    }
  }

  TPartType? getPart<TPartType extends MvcControllerPart>() => _partProvider.tryGet<TPartType>();
  dynamic getPartByType(Type partType) => _partProvider.tryGetByType(partType);

  @override
  MvcStateValue<T>? getStateValue<T>({Object? key}) {
    for (var element in _partTypes) {
      var stateValue = (_partProvider.getByType(element) as MvcControllerPart).getStateValue<T>(key: key);
      if (stateValue != null) {
        return stateValue;
      }
    }
    return null;
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    var privoider = buildScopedServiceProvider(
      builder: (collection) {
        collection.addSingleton<ServiceCollection>((serviceProvider) => _MvcControllerPartCollection(this));
      },
    );
    _partProvider = privoider.buildScoped(
      builder: (collection) {
        getService<MvcController>().initPart(privoider.get<ServiceCollection>() as MvcControllerPartCollection);
      },
    );
  }
}
