import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

abstract class MvcController<TModelType> with DependencyInjectionService {
  late MvcControllerState _state;
  TModelType get model => _state.widget.model;
  BuildContext get context => _state.context;

  MvcView view();

  @protected
  void init() {}
  @protected
  void didUpdateModel(TModelType oldModel) {}
  @mustCallSuper
  @protected
  void activate() {}
  @mustCallSuper
  @protected
  void deactivate() {}
  @mustCallSuper
  @protected
  void initService(ServiceCollection collection) {}

  void update() => _state._update();
  void updateWidget<T extends MvcWidget>() => _find(MvcWidgetQueryPredicate.makeWithWidgetType(T)).update();
  void updateService<T extends Object>() => _find(MvcWidgetQueryPredicate.makeWithServiceType(T)).update();
  Iterable<MvcWidgetUpdater> $(String q) {
    return _find(MvcWidgetQueryPredicate.makeWithQuery(q));
  }

  Iterable<MvcWidgetUpdater> _find(MvcWidgetQueryPredicate predicate) {
    return (context as MvcWidgetElement).manager.query(predicate);
  }
}

class MvcProxyController extends MvcController<Widget> {
  MvcProxyController();
  @override
  MvcView view() => MvcViewBuilder((controller) => model);
}

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends MvcStatefulWidget {
  const Mvc({this.create, TModelType? model, Key? key})
      : model = model ?? model as TModelType,
        super(key: key);
  final TControllerType Function()? create;
  final TModelType model;

  @override
  MvcWidgetState createState() => MvcControllerState<TControllerType, TModelType>();
}

class MvcProxy<TControllerType extends MvcController<Widget>> extends StatelessWidget {
  const MvcProxy({this.create, required this.child, super.key});
  final TControllerType Function()? create;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Mvc(create: create, model: child);
  }
}

class MvcControllerState<TControllerType extends MvcController<TModelType>, TModelType> extends MvcWidgetState {
  @override
  Mvc<TControllerType, TModelType> get widget => super.widget as Mvc<TControllerType, TModelType>;

  void _update() {
    setState(() {});
  }

  @override
  bool get blockParentFind => true;

  @mustCallSuper
  @override
  void didUpdateWidget(covariant MvcStatefulWidget<MvcController> oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.didUpdateModel(widget.model);
  }

  @mustCallSuper
  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @mustCallSuper
  @override
  void activate() {
    super.activate();
    controller.activate();
  }

  @mustCallSuper
  @override
  void deactivate() {
    super.deactivate();
    controller.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return getService<MvcView>().buildView();
  }

  @mustCallSuper
  @override
  void providerService(ServiceCollection collection, ServiceProvider parentServiceProvider) {
    super.providerService(collection, parentServiceProvider);
    TControllerType controller = widget.create?.call() ?? parentServiceProvider.get<_MvcControllerProvider<TControllerType>>().create();
    controller._state = this;
    collection.addSingleton<MvcController>((_) => controller, initializeWhenServiceProviderBuilt: true);
    collection.addSingleton<MvcView>(
      (serviceProvider) {
        return controller.view();
      },
    );
    if (TControllerType != MvcController) {
      collection.addSingleton<TControllerType>((_) => controller, initializeWhenServiceProviderBuilt: true);
    }
    controller.initService(collection);
  }
}

abstract class MvcView<TControllerType extends MvcController> with DependencyInjectionService {
  late final TControllerType controller = getService<MvcController>() as TControllerType;
  BuildContext get context => controller.context;

  Widget buildView();
}

class MvcViewBuilder<TControllerType extends MvcController> extends MvcView<TControllerType> {
  MvcViewBuilder(this.builder);
  final Widget Function(TControllerType controller) builder;
  @override
  Widget buildView() => builder(controller);
}

class MvcHeader extends MvcBuilder {
  const MvcHeader({required super.builder, super.id, super.classes, super.key});
}

class MvcBody extends MvcBuilder {
  const MvcBody({required super.builder, super.id, super.classes, super.key});
}

class MvcFooter extends MvcBuilder {
  const MvcFooter({required super.builder, super.id, super.classes, super.key});
}

class MvcDependencyProvider extends MvcStatefulWidget {
  const MvcDependencyProvider({required this.child, required this.provider, super.key});
  final void Function(ServiceCollection collection)? provider;
  final Widget child;

  @override
  MvcWidgetState<MvcStatefulWidget<MvcController>, MvcController> createState() => MvcDependencyProviderState();
}

class MvcDependencyProviderState extends MvcWidgetState<MvcDependencyProvider, MvcController> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return widget.child;
      },
    );
  }

  @override
  void providerService(ServiceCollection collection, ServiceProvider parentServiceProvider) {
    super.providerService(collection, parentServiceProvider);
    widget.provider?.call(collection);
  }
}

class MvcRootcDependencyServiceProvider extends StatelessWidget {
  const MvcRootcDependencyServiceProvider({required this.serviceProvider, required this.child, super.key});
  final ServiceProvider serviceProvider;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    assert(context.getInheritedWidgetOfExactType<InheritedServiceProvider>() == null, "MvcRootcDependencyServiceProvider can only be used in the root mvc widget");
    return InheritedServiceProvider(
      serviceProvider: serviceProvider,
      child: child,
    );
  }
}

abstract class _MvcControllerProvider<T extends MvcController> {
  T create();
}

class _MvcControllerFactoryProvider<T extends MvcController> extends _MvcControllerProvider<T> {
  _MvcControllerFactoryProvider(this.factory);
  final T Function() factory;
  @override
  T create() => factory();
}

extension MvcControllerServiceCollection on ServiceCollection {
  void addController<T extends MvcController>(T Function(ServiceProvider provider) create) {
    add<_MvcControllerProvider<T>>((serviceProvider) => _MvcControllerFactoryProvider<T>(() => create(serviceProvider)));
  }
}
