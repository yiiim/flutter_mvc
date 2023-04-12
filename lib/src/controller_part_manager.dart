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

class MvcControllerPartManager extends ServiceCollection with DependencyInjectionService {
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
  FutureOr dependencyInjectionServiceInitialize() {
    var privoider = buildScopeService(
      builder: (collection) {
        collection.addSingleton<ServiceCollection>((serviceProvider) => _MvcControllerPartCollection(this));
      },
    );
    _partProvider = privoider.buildScope(
      builder: (collection) {
        getService<MvcController>().buildPart(privoider.get<ServiceCollection>() as MvcControllerPartCollection);
      },
    );
  }
}
