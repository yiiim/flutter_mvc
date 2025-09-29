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
  bool get isSelectorBreaker => true;
  bool get createStateScope => true;

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

  void update([void Function()? fn]) => _state!._update(fn);

  @override
  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]) => context.querySelectorAll<T>(
        selectors,
        ignoreSelectorBreaker,
      );
  @override
  MvcWidgetUpdater? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]) => context.querySelector<T>(
        selectors,
        ignoreSelectorBreaker,
      );
}

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends MvcStatefulWidget {
  const Mvc({this.create, TModelType? model, Key? key, super.id, super.classes})
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

class _MvcControllerState<TControllerType extends MvcController<TModelType>, TModelType> extends MvcWidgetState {
  @override
  Mvc<TControllerType, TModelType> get widget => super.widget as Mvc<TControllerType, TModelType>;

  late final TControllerType controller = getService<TControllerType>();

  void _update([void Function()? fn]) {
    setState(fn ?? () {});
  }

  @override
  bool get isSelectorBreaker => controller.isSelectorBreaker;
  @override
  bool get createStateScope => controller.createStateScope;

  @mustCallSuper
  @override
  void didUpdateWidget(covariant MvcStatefulWidget oldWidget) {
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
    collection.add<MvcView>(
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
