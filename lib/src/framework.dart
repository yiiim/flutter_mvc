import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

/// mvc framework widget
mixin MvcWidget<TControllerType extends MvcController> on Widget {
  String? get id;
  List<String>? get classes;
}

/// mvc framework context
abstract class MvcContext<TControllerType extends MvcController> extends BuildContext {
  TControllerType get controller;
}

/// mvc framework stateless widget
///
/// [build] method context can cast to [MvcContext]
abstract class MvcStatelessWidget<TControllerType extends MvcController> extends StatelessWidget with MvcWidget {
  const MvcStatelessWidget({this.id, this.classes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;

  @override
  StatelessElement createElement() => MvcStatelessElement<TControllerType>(this);
}

/// mvc framework stateless element
class MvcStatelessElement<TControllerType extends MvcController> extends StatelessElement with MvcWidgetElement<TControllerType> {
  MvcStatelessElement(MvcStatelessWidget widget) : super(widget);
}

/// mvc builder
class MvcBuilder<TControllerType extends MvcController> extends MvcStatelessWidget<TControllerType> {
  const MvcBuilder({super.key, super.classes, super.id, required this.builder});
  final Widget Function(MvcContext<TControllerType> context) builder;
  @override
  Widget build(BuildContext context) {
    return builder(context as MvcContext<TControllerType>);
  }
}

/// mvc framework stateful widget
abstract class MvcStatefulWidget<TControllerType extends MvcController> extends StatefulWidget with MvcWidget {
  const MvcStatefulWidget({this.id, this.classes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;

  @override
  StatefulElement createElement() => MvcStatefulElement<TControllerType>(this);

  @override
  MvcWidgetState<MvcStatefulWidget<TControllerType>, TControllerType> createState();
}

class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with MvcWidgetElement<TControllerType> {
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget);

  @override
  bool get blockParentFind => (state as MvcWidgetState?)?.blockParentFind ?? super.blockParentFind;

  @override
  void _providerService(ServiceCollection collection, ServiceProvider parentServiceProvider) {
    super._providerService(collection, parentServiceProvider);
    (state as MvcWidgetState).providerService(collection, parentServiceProvider);
  }
}

mixin _DisposeHelper<T extends StatefulWidget> on State<T> {
  void _dispose() => super.dispose();
}

abstract class MvcWidgetState<T extends MvcStatefulWidget<TControllerType>, TControllerType extends MvcController> extends State<T> with _DisposeHelper, DependencyInjectionService {
  TControllerType get controller => getService();
  bool get blockParentFind => false;
  @override
  MvcContext<TControllerType> get context => super.context as MvcContext<TControllerType>;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
  }

  @mustCallSuper
  void providerService(ServiceCollection collection, ServiceProvider parentServiceProvider) {
    collection.addSingleton<MvcWidgetState>((serviceProvider) => this, initializeWhenServiceProviderBuilt: true);
    if (MvcWidgetState<T, TControllerType> != MvcWidgetState) {
      collection.addSingleton<MvcWidgetState<T, TControllerType>>((serviceProvider) => this);
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}

/// mvc framework InheritedWidget
class InheritedServiceProvider extends InheritedWidget {
  const InheritedServiceProvider({super.key, required this.serviceProvider, required super.child});
  final ServiceProvider serviceProvider;
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }

  static ServiceProvider? of(BuildContext context) {
    final InheritedServiceProvider? inheritedServiceProvider = context.getElementForInheritedWidgetOfExactType<InheritedServiceProvider>()?.widget as InheritedServiceProvider?;
    return inheritedServiceProvider?.serviceProvider;
  }
}

mixin MvcWidgetElement<TControllerType extends MvcController> on ComponentElement implements MvcContext<TControllerType> {
  late final MvcWidgetManager manager = MvcWidgetManager(this, blocker: blockParentFind);
  late final Set<MvcService> _dependencieServices = {};
  ServiceProvider? _serviceProvider;
  ServiceProvider get serviceProvider {
    return _serviceProvider!;
  }

  bool get blockParentFind => false;
  @override
  MvcWidget get widget => super.widget as MvcWidget;

  TControllerType? _controller;
  @override
  TControllerType get controller {
    assert(_controller != null);
    return _controller!;
  }

  void _providerService(ServiceCollection collection, ServiceProvider parentServiceProvider) {}

  T dependOnService<T extends MvcService>() {
    var service = controller.getService<T>();
    _dependencieServices.add(service);
    service._updateDependencies(this);
    return service;
  }

  T? tryDependOnService<T extends MvcService>() {
    var service = controller.tryGetService<T>();
    if (service != null) {
      _dependencieServices.add(service);
      service._updateDependencies(this);
    }
    return service;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    ServiceProvider? parentServiceProvider;
    if (parent != null) {
      parentServiceProvider = InheritedServiceProvider.of(parent);
    }
    if (parentServiceProvider == null) {
      ServiceCollection collection = ServiceCollection();
      if (TControllerType == MvcController) {
        collection.addSingleton<MvcController>((serviceProvider) => _MvcRootController());
      }
      parentServiceProvider = collection.build();
    } else if (parentServiceProvider.tryGet<MvcController>() == null) {
      parentServiceProvider = parentServiceProvider.buildScoped(
        builder: (collection) {
          if (TControllerType == MvcController) {
            collection.addSingleton<MvcController>((serviceProvider) => _MvcRootController());
          }
        },
      );
    }
    _controller = parentServiceProvider.tryGet<TControllerType>();

    _serviceProvider = parentServiceProvider.buildScoped(
      builder: (collection) {
        collection.addSingleton<MvcWidgetManager>((_) => manager);
        _providerService(collection, parentServiceProvider!);
      },
    );
    manager.mount(parent: parentServiceProvider.tryGet<MvcWidgetManager>());

    assert(_controller != null, '$TControllerType not found in this context');
    super.mount(parent, newSlot);
  }

  @override
  void activate() {
    super.activate();
    Element? newParent;
    visitAncestorElements(
      (element) {
        newParent = element;
        return false;
      },
    );
    MvcWidgetManager? newParentManager;
    if (newParent != null) {
      newParentManager = InheritedServiceProvider.of(newParent!)?.tryGet<MvcWidgetManager>();
    }
    _dependencieServices.clear();
    manager.activate(newParent: newParentManager);
  }

  @override
  void deactivate() {
    super.deactivate();
    manager.deactivate();
    for (var element in _dependencieServices) {
      element._dependents.remove(this);
    }
  }

  @override
  void unmount() {
    super.unmount();
    manager.unmount();
    _dependencieServices.clear();
    _serviceProvider?.dispose();
  }

  @override
  Widget build() {
    return InheritedServiceProvider(
      serviceProvider: serviceProvider,
      child: super.build(),
    );
  }
}

class _MvcRootController extends MvcController {
  @override
  MvcView view() {
    throw UnimplementedError();
  }
}

/// with the service get power for update [MvcServiceScope]
mixin MvcService on DependencyInjectionService {
  late final Set<MvcWidgetElement> _dependents = <MvcWidgetElement>{};

  void update() {
    for (var element in _dependents) {
      element.markNeedsBuild();
    }
  }

  void _updateDependencies(MvcWidgetElement element) {
    _dependents.add(element);
  }

  void updateWidget<T extends MvcWidget>() => _find(MvcWidgetQueryPredicate.makeWithWidgetType(T)).update();
  void updateService<T extends Object>() => _find(MvcWidgetQueryPredicate.makeWithServiceType(T)).update();
  Iterable<MvcWidgetUpdater> $(String q) sync* {
    for (var element in _dependents) {
      yield* element.manager.query(MvcWidgetQueryPredicate.makeWithQuery(q));
    }
  }

  Iterable<MvcWidgetUpdater> _find(MvcWidgetQueryPredicate predicate) {
    return getService<MvcWidgetManager>().query(predicate);
  }

  @override
  void dispose() {
    super.dispose();
    _dependents.clear();
  }
}

/// You can update this Widget using the following methods：
/// ## update at controlle
/// ```dart
/// // in the MvcView
/// MvcServiceScope<TestService>(
///    builder: (context, service) {
///       return Text(service.title);
///    },
/// )
///
/// // in the MvcController, will be update all MvcServiceScope<TestService>
/// updateService<TestService>();
/// ```
/// ---
/// ## update at the service
///
/// ```dart
/// // anywhere
/// MvcServiceScope<TestService>(
///    builder: (context, service) {
///       return Text(service.title);
///    },
/// )
///
/// // in the TestService
/// class TestService with DependencyInjectionService, MvcService {
///   String title = "Test Title";
///   void changeTitle(String newTitle) {
///     title = newTitle;
///     // will be update all MvcServiceScope<TestService>
///     update();
///   }
/// }
/// ```
class MvcServiceScope<TServiceType extends Object> extends MvcStatelessWidget {
  const MvcServiceScope({required this.builder, super.id, super.classes, super.key});
  final Widget Function(MvcContext context, TServiceType) builder;

  @override
  Widget build(BuildContext context) {
    var element = context as _MvcStateScopeElement<TServiceType>;
    return builder(element, element._service);
  }

  @override
  StatelessElement createElement() {
    return _MvcStateScopeElement<TServiceType>(this);
  }
}

class _MvcStateScopeElement<TServiceType extends Object> extends MvcStatelessElement {
  _MvcStateScopeElement(super.widget);
  late final TServiceType _service = controller.getService();
  late final MvcWidgetManager _manager = _MvcStateScopeManager<TServiceType>(this);
  @override
  MvcWidgetManager get manager => _manager;

  @override
  void activate() {
    super.activate();
    if (_service is MvcService) {
      (_service as MvcService)._dependents.add(this);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_service is MvcService) {
      (_service as MvcService)._dependents.remove(this);
    }
  }
}

class _MvcStateScopeManager<TServiceType extends Object> extends MvcWidgetManager {
  _MvcStateScopeManager(super.element);

  @override
  bool isMatch(MvcWidgetQueryPredicate predicate) {
    if (predicate.serviceType != null) {
      if (predicate.serviceType == TServiceType) {
        return true;
      }
    }
    return super.isMatch(predicate);
  }
}
