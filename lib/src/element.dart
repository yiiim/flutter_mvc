part of './flutter_mvc.dart';

class MvcElement<TControllerType extends MvcController<TModelType>, TModelType> extends EasyTreeRelationElement with DependencyInjectionService implements MvcContext<TControllerType, TModelType> {
  MvcElement(Mvc<TControllerType, TModelType> widget, this.create) : super(widget, easyTreeOwner: MvcOwner.sharedOwner);

  final TControllerType Function()? create;
  late final TControllerType _controller = () {
    var scopedBuilder = parent() ?? easyTreeOwner as MvcOwner;
    var scopedService = (scopedBuilder as DependencyInjectionService);
    var controller = create?.call() ?? scopedService.getService<MvcControllerProvider<TControllerType>>().create();
    var provider = scopedService.buildScopedServiceProvider(
      builder: (collection) {
        assert(collection is MvcServiceCollection);
        collection.addSingleton<MvcController>((_) => controller, initializeWhenServiceProviderBuilt: true);
        collection.addSingleton<MvcContext>((serviceProvider) => this, initializeWhenServiceProviderBuilt: true);
        collection.addSingleton<MvcView>(
          (serviceProvider) {
            return controller.view();
          },
        );
        collection.addSingleton<MvcControllerPartManager>((serviceProvider) => MvcControllerPartManager());
        collection.addSingleton(
          (serviceProvider) {
            var manager = MvcWidgetManager();
            scopedService.tryGetService<MvcWidgetManager>()?._registerChild(manager);
            return manager;
          },
        );
        collection.addSingleton<MvcControllerEnvironmentState>((serviceProvider) => MvcControllerEnvironmentState(parent: scopedService.tryGetService<MvcControllerEnvironmentState>()));
        collection.addSingleton<MvcStateProvider>((serviceProvider) => serviceProvider.get<MvcController>());
        if (TControllerType != MvcController) {
          collection.addSingleton<TControllerType>((_) => controller, initializeWhenServiceProviderBuilt: true);
        }
        controller.initService(collection as MvcServiceCollection);
      },
      scope: controller,
    );
    return provider.get<TControllerType>();
  }();

  @override
  void update(covariant Widget newWidget) {
    var oldWidget = widget;
    if ((oldWidget as Mvc<TControllerType, TModelType>?)?.model != (newWidget as Mvc<TControllerType, TModelType>?)?.model) {
      _controller.updateState<TModelType>(updater: (state) => state.value = (newWidget as Mvc<TControllerType, TModelType>).model);
    }
    super.update(newWidget);
  }

  @override
  void mountEasyTree(EasyTreeNode? parent) {
    super.mountEasyTree(parent);
    _controller.addListener(markNeedsBuild);
    _controller.initState<TModelType>((widget as Mvc<TControllerType, TModelType>).model);
    assert(_controller._element == null);
    _controller._element = this;
    _controller.init();
    assert(_controller._debugTypesAreRight((widget as Mvc<TControllerType, TModelType>).model), "请为${_controller.runtimeType}提供正确的Model");
  }

  @override
  void activate() {
    super.activate();
    _controller.activate();
  }

  @override
  void deactivate() {
    super.deactivate();
    _controller.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    _controller.removeListener(markNeedsBuild);
    _controller._element = null;
    _controller.dispose();
  }

  @override
  T? parent<T extends MvcController>() => (easyTreeGetParent(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  @override
  T? child<T extends MvcController>({bool sort = false}) {
    if (sort) {
      return (easyTreeGetSortedChild(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    }
    return (easyTreeGetChild(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? find<T extends MvcController>({bool sort = false}) {
    if (sort) {
      return (easyTreeGetSortedChildInAll(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    }
    return (easyTreeGetChildInAll(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? previousSibling<T extends MvcController>({bool sort = false}) {
    if (sort) {
      return (easyTreeGetSortedPreviousSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    }
    return (easyTreeGetPreviousSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? nextSibling<T extends MvcController>({bool sort = false}) {
    if (sort) {
      return (easyTreeGetSortedNextSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    }
    return (easyTreeGetNextSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) {
    if (sort) {
      return (easyTreeGetSortedSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    }
    return (easyTreeGetSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? forward<T extends MvcController>({bool sort = false}) => previousSibling<T>(sort: sort) ?? parent<T>();

  @override
  T? backward<T extends MvcController>({bool sort = false}) => nextSibling<T>(sort: sort) ?? find<T>(sort: sort);

  @override
  List<EasyTreeNodeKey> get keys => [
        EasyTreeNodeKey<Type>(_controller.runtimeType),
        const EasyTreeNodeKey<Type>(MvcController),
        EasyTreeNodeKey<MvcController>(_controller),
        if (TControllerType != MvcController && TControllerType != _controller.runtimeType) EasyTreeNodeKey<Type>(TControllerType),
      ];

  @override
  Widget buildChild() => getService<MvcView>()._buildView(this);

  @override
  TControllerType get controller => _controller;

  @override
  TModelType get model => (widget as Mvc<TControllerType, TModelType>).model;

  @override
  BuildContext get buildContext => this;
}
