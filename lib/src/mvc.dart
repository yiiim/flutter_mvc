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
  List<MvcWidgetUpdater> $(String q) {
    return (context as MvcWidgetElement).manager.query(MvcWidgetQueryPredicate.make(q));
  }
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

class MvcControllerState<TControllerType extends MvcController<TModelType>, TModelType> extends MvcWidgetState {
  @override
  Mvc<TControllerType, TModelType> get widget => super.widget as Mvc<TControllerType, TModelType>;

  void _update() {
    setState(() {});
  }

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

abstract class MvcView<TControllerType extends MvcController<TModelType>, TModelType> with DependencyInjectionService {
  late final TControllerType controller = getService<MvcController>() as TControllerType;
  TModelType get model => controller.model;
  BuildContext get context => controller.context;

  Widget buildView();
}

class MvcViewBuilder<TControllerType extends MvcController<TModelType>, TModelType> extends MvcView<TControllerType, TModelType> {
  MvcViewBuilder(this.builder);
  final Widget Function(TControllerType controller) builder;
  @override
  Widget buildView() => builder(controller);
}

/// Mvc依赖提供者，可以使用[MvcDependencyProvider]为子级提供依赖
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
