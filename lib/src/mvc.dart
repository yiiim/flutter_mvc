import 'package:dart_dependency_injection/dart_dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/src/selector/node.dart';

import 'framework.dart';
import 'selector.dart';

/// Extend this class to create a mvc controller, and override [view] method to return a [MvcView]
abstract class MvcController<TModelType> with DependencyInjectionService implements MvcWidgetSelector {
  _MvcControllerState? _state;
  TModelType get model => _state!.widget.model;
  MvcContext get context => _state!.context;

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
  void initServices(ServiceCollection collection) {}

  void update<T extends MvcWidget>() => _state!._update();

  @override
  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors]) => context.querySelectorAll<T>(selectors);
  @override
  MvcWidgetUpdater? querySelector<T>([String? selectors]) => context.querySelector<T>(selectors);
}

/// TODO: it's can't update when call [update] method
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
  MvcWidgetState createState() => _MvcControllerState<TControllerType, TModelType>();

  static Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors]) {
    return MvcImplicitRootNode.instance.querySelectorAll<T>(selectors);
  }

  static MvcWidgetUpdater? querySelector<T>([String? selectors]) {
    return MvcImplicitRootNode.instance.querySelector<T>(selectors);
  }
}

class MvcProxy<TControllerType extends MvcController<Widget>> extends Mvc<TControllerType, Widget> {
  const MvcProxy({super.create, required Widget child, super.key}) : super(model: child);
}

class _MvcControllerState<TControllerType extends MvcController<TModelType>, TModelType> extends MvcWidgetState {
  @override
  Mvc<TControllerType, TModelType> get widget => super.widget as Mvc<TControllerType, TModelType>;

  void _update() {
    setState(() {});
  }

  @override
  bool get isSelectorBreaker => true;

  @mustCallSuper
  @override
  void didUpdateWidget(covariant MvcStatefulWidget<MvcController> oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.didUpdateModel((oldWidget as Mvc<TControllerType, TModelType>).model);
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
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
    TControllerType? controller = widget.create?.call() ?? parent?.get<_MvcControllerProvider<TControllerType>>().create();
    assert(controller != null, "can't create controller");
    controller!._state = this;
    collection.addSingleton<MvcController>((_) => controller, initializeWhenServiceProviderBuilt: true);
    collection.addSingleton<MvcView>(
      (serviceProvider) {
        return controller.view();
      },
    );
    if (TControllerType != MvcController) {
      collection.addSingleton<TControllerType>((_) => controller);
    }
    controller.initServices(collection);
  }
}

abstract class MvcView<TControllerType extends MvcController> with DependencyInjectionService {
  late final TControllerType controller = getService<TControllerType>();
  BuildContext get context => controller.context;

  Widget buildView();
}

class MvcViewBuilder<TControllerType extends MvcController> extends MvcView<TControllerType> {
  MvcViewBuilder(this.builder);
  final Widget Function(TControllerType controller) builder;
  @override
  Widget buildView() => builder(controller);
}

class MvcDependencyProvider extends MvcStatefulWidget {
  const MvcDependencyProvider({required this.child, required this.provider, super.key});
  final void Function(ServiceCollection collection)? provider;
  final Widget child;

  @override
  MvcWidgetState<MvcStatefulWidget<MvcController>, MvcController> createState() => _MvcDependencyProviderState();
}

class _MvcDependencyProviderState extends MvcWidgetState<MvcDependencyProvider, MvcController> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return widget.child;
      },
    );
  }

  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
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
    addSingleton<_MvcControllerProvider<T>>((serviceProvider) => _MvcControllerFactoryProvider<T>(() => create(serviceProvider)));
  }
}
