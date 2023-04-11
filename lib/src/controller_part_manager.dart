part of './flutter_mvc.dart';

class MvcControllerPartManager extends ServiceCollection with DependencyInjectionService implements MvcControllerPartCollection {
  late final List<Type> _partTypes = [];
  void init() {
    for (var element in _partTypes) {
      (getServiceByType(element) as MvcControllerPart).init();
    }
  }

  TPartType? getPart<TPartType extends MvcControllerPart>() => tryGetService<TPartType>();
  dynamic getPartByType(Type partType) => tryGetServiceByType(partType);

  @override
  void addPart<TPartType extends MvcControllerPart>(TPartType part) {
    _partTypes.add(TPartType);
    addSingleton<TPartType>((serviceProvider) => part, initializeWhenServiceProviderBuilt: true);
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    waitServicesInitialize();
    var privoider = buildScopeService(
      builder: (collection) {
        collection.addSingleton<ServiceCollection>((serviceProvider) => this);
      },
    );
    privoider.buildScope(
      builder: (collection) {
        assert(collection == this);
        getService<MvcController>().buildPart(this);
      },
    );
  }
}
