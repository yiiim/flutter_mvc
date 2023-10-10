import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

/// mvc framework widget
mixin MvcWidget<TControllerType extends MvcController> on Widget {
  String? get id;
  List<String>? get classes;
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

/// mvc framework context
abstract class MvcContext<TControllerType extends MvcController> extends BuildContext {
  TControllerType get controller;
  T dependOnService<T extends Object>();
  T? tryDependOnService<T extends Object>();
}

mixin MvcWidgetElement<TControllerType extends MvcController> on ComponentElement implements MvcContext<TControllerType> {
  late final MvcWidgetManager _widgetManager = MvcWidgetManager(this, blocker: blockParentFind);
  late final Map<Type, Object> _dependencieServices = {};

  ServiceProvider? _serviceProvider;
  ServiceProvider get serviceProvider {
    assert(_serviceProvider != null, 'Use the serviceProvider must after the widget has been mounted.');
    return _serviceProvider!;
  }

  bool get blockParentFind => false;
  @override
  MvcWidget get widget => super.widget as MvcWidget;

  TControllerType? _controller;
  @override
  TControllerType get controller {
    assert(_controller != null, '$TControllerType not found in current context');
    return _controller!;
  }

  @mustCallSuper
  void initServices(ServiceCollection collection, ServiceProvider parent) {}

  @override
  T dependOnService<T extends Object>() {
    var service = serviceProvider.get<T>();
    _dependencieServices[T] = service;
    if (service is MvcService) {
      service._updateDependencies(this);
    }
    return service;
  }

  @override
  T? tryDependOnService<T extends Object>() {
    var service = serviceProvider.tryGet<T>();
    if (service != null) {
      _dependencieServices[T] = service;
      if (service is MvcService) {
        service._updateDependencies(this);
      }
    }
    return service;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    ServiceProvider? parentServiceProvider;
    if (parent != null) {
      parentServiceProvider = InheritedServiceProvider.of(parent) ?? MvcOwner.of(parent)?.services;
    }
    assert(parentServiceProvider != null, 'MvcWidget must be mounted under a MvcApp');

    _controller = parentServiceProvider!.tryGet<TControllerType>();
    _serviceProvider = parentServiceProvider.buildScoped(
      builder: (collection) {
        collection.addSingleton<MvcWidgetManager>((_) => _widgetManager);
        initServices(collection, parentServiceProvider!);
      },
    );
    _widgetManager.mount(parent: parentServiceProvider.tryGet<MvcWidgetManager>());

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
    _widgetManager.activate(newParent: newParentManager);
  }

  @override
  void deactivate() {
    super.deactivate();
    _widgetManager.deactivate();
    for (var element in _dependencieServices.values) {
      if (element is MvcService) {
        element._dependents.remove(this);
      }
    }
  }

  @override
  void unmount() {
    super.unmount();
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

/// mvc framework stateless element
class MvcStatelessElement<TControllerType extends MvcController> extends StatelessElement with MvcWidgetElement<TControllerType> {
  MvcStatelessElement(MvcStatelessWidget widget) : super(widget);
}

/// mvc framework stateful element
class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with MvcWidgetElement<TControllerType> {
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget);

  @override
  bool get blockParentFind => (state as MvcWidgetState?)?.blockParentFind ?? super.blockParentFind;

  @override
  void initServices(ServiceCollection collection, ServiceProvider parent) {
    super.initServices(collection, parent);
    (state as MvcWidgetState?)?.initServices(collection, parent);
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
  void initServices(ServiceCollection collection, ServiceProvider parent) {
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

class MvcOwner extends MvcProxyController {
  MvcOwner({ServiceProvider? serviceProvider}) : services = serviceProvider ?? ServiceCollection().build();
  ServiceProvider services;
  static MvcOwner? of(BuildContext context) {
    final InheritedMvcOwner? inheritedServiceProvider = context.getElementForInheritedWidgetOfExactType<InheritedMvcOwner>()?.widget as InheritedMvcOwner?;
    return inheritedServiceProvider?.owner;
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
      yield* element._widgetManager.query(MvcWidgetQueryPredicate.makeWithQuery(q));
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
class MvcServiceScope<TServiceType extends Object> extends MvcStatefulWidget {
  const MvcServiceScope({required this.builder, super.id, super.classes, super.key});
  final Widget Function(MvcContext context, TServiceType) builder;

  @override
  MvcWidgetState<MvcStatefulWidget<MvcController>, MvcController> createState() => _MvcServiceScopeState<TServiceType>();
}

class _MvcServiceScopeState<TServiceType extends Object> extends MvcWidgetState<MvcServiceScope<TServiceType>, MvcController> {
  late final TServiceType _service = getService<TServiceType>();
  @override
  Widget build(BuildContext context) {
    this.context.dependOnService<TServiceType>();
    return widget.builder(this.context, _service);
  }
}

class MvcWidgetManager implements MvcWidgetUpdater {
  MvcWidgetManager(this._element, {this.blocker = false});
  MvcWidgetManager? _parent;
  final MvcWidgetElement? _element;
  final bool blocker;
  late final List<MvcWidgetManager> _children = [];

  void mount({MvcWidgetManager? parent}) {
    _parent = parent;
    _parent?._children.add(this);
  }

  void activate({MvcWidgetManager? newParent}) {
    _parent = newParent;
    _parent?._children.add(this);
  }

  void deactivate() {
    _parent?._children.remove(this);
  }

  bool isMatch(MvcWidgetQueryPredicate predicate) {
    if (predicate.id != null) {
      if (_element?.widget.id == predicate.id) {
        return true;
      }
    }
    if (predicate.classes != null) {
      if (_element?.widget.classes?.contains(predicate.classes) == true) {
        return true;
      }
    }
    if (predicate.type != null) {
      if (_element?.widget.runtimeType == predicate.type) {
        return true;
      }
    }
    if (predicate.typeString != null) {
      if (_element?.widget.runtimeType.toString() == predicate.typeString) {
        return true;
      }
    }
    if (predicate.serviceType != null) {
      if (_element?._dependencieServices.containsKey(predicate.serviceType) == true) {
        return true;
      }
    }
    return false;
  }

  Iterable<MvcWidgetUpdater> query(MvcWidgetQueryPredicate predicate) sync* {
    for (var item in _children) {
      if (item.isMatch(predicate)) {
        yield item;
        if (predicate.id != null) return;
      }
      if (!item.blocker) yield* item.query(predicate);
    }
  }

  @override
  void update() {
    _element?.markNeedsBuild();
  }
}

class MvcApp extends StatefulWidget {
  const MvcApp({required this.child, this.owner, super.key});
  final MvcOwner? owner;
  final Widget child;

  @override
  State<MvcApp> createState() => _MvcAppState();
}

class InheritedMvcOwner extends InheritedWidget {
  const InheritedMvcOwner({required this.owner, super.key, required super.child});
  final MvcOwner owner;
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _MvcAppState extends State<MvcApp> {
  late final ServiceProvider serviceProvider;
  late final MvcOwner owner;
  @override
  void initState() {
    super.initState();
    owner = widget.owner ?? MvcOwner();
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (context.getElementForInheritedWidgetOfExactType<InheritedServiceProvider>() != null) {
        throw Exception("MvcApp can only be used in the root mvc widget");
      }
      return true;
    }());

    return InheritedMvcOwner(
      owner: owner,
      child: Mvc<MvcOwner, Widget>(
        create: () => owner,
        model: widget.child,
      ),
    );
  }
}
