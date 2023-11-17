import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

import 'context.dart';

/// Mvc framework widget
///
/// Don't use this class directly, use [MvcStatelessWidget] or [MvcStatefulWidget] instead.
///
/// Can be update by [MvcController.$] if extends [MvcStatelessWidget] or [MvcStatefulWidget].
///
/// Example:
/// ```dart
/// class MyWidget extends MvcStatelessWidget {
///   const MyWidget({required this.title, super.key, super.id, super.classes});
///   final String title;
///   @override
///   Widget build(BuildContext context) {
///     return Text(title);
///   }
/// }
/// // In the controller
/// class MyController extends MvcController {
///   void updateMyWidget() {
///     $<MyWidget>().update(() => title = "MyWidget Title Updated");
///   }
/// }
/// // In the view
/// class MyView extends MvcView {
///   @override
///   MvcViewBuilder build(BuildContext context) {
///     return MyWidget(title: controller.title);
///   }
/// }
/// ```
///
/// Also can be update by [MvcController.$] if [MvcWidget.id] or [MvcWidget.classes] be set.
///
/// Example:
/// ```dart
/// class MyWidget extends MvcStatelessWidget {
///   const MyWidget({required this.title, super.key, super.id, super.classes});
///   final String title;
///   @override
///   Widget build(BuildContext context) {
///     return Text(title);
///   }
/// }
/// // In the controller
/// class MyController extends MvcController {
///   String title = "MyWidget Title";
///   void updateMyWidget() {
///     $("#my-widget").update(() => title = "MyWidget Title Updated");; // or $(".my-widget").update(() => title = "MyWidget Title Updated");;
///   }
/// }
/// // In the view
/// class MyView extends MvcView {
///   @override
///   MvcViewBuilder build(BuildContext context) {
///     return MyWidget(title: controller.title, id: "my-widget", classes: ["my-widget"]);
///   }
/// }
/// ```
mixin MvcWidget<TControllerType extends MvcController> on Widget {
  String? get id;
  List<String>? get classes;
}

/// Mvc framework stateless widget
///
/// [build] method context can cast to [MvcContext<TControllerType>]
///
/// About how to update this widget, see [MvcWidget]
abstract class MvcStatelessWidget<TControllerType extends MvcController> extends StatelessWidget with MvcWidget {
  const MvcStatelessWidget({this.id, this.classes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;

  @override
  StatelessElement createElement() => MvcStatelessElement<TControllerType>(this);
}

/// Mvc framework stateful widget
///
/// About how to update this widget, see [MvcWidget]
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



/// The common element of the [MvcWidget]
mixin MvcWidgetElement<TControllerType extends MvcController> on ComponentElement implements MvcContext<TControllerType> {
  late final MvcWidgetManager _widgetManager = MvcWidgetManager(this, blocker: isUpdaterQueryerBreaker);
  late final Map<Type, Object> _dependencieServices = {};

  ServiceProvider? _serviceProvider;

  /// Every [MvcWidget] will to create a [ServiceProvider] as a new scope
  ServiceProvider get serviceProvider {
    assert(_serviceProvider != null, 'Use the serviceProvider must after the widget has been mounted.');
    return _serviceProvider!;
  }

  /// Whether to allow queries from superiors to continue looking for children
  bool get isUpdaterQueryerBreaker => false;
  @override
  MvcWidget get widget => super.widget as MvcWidget;

  TControllerType? _controller;

  /// the nearest [Mvc]'s controller in this context if of type [TControllerType]
  @override
  TControllerType get controller {
    assert(_controller != null, '$TControllerType not found in current context');
    return _controller!;
  }

  /// you can be inject some services here when [ServiceProvider] is created
  @mustCallSuper
  void initServices(ServiceCollection collection, ServiceProvider parent) {}

  /// see the [MvcContext.dependOnService]
  @override
  T dependOnService<T extends Object>() {
    var service = serviceProvider.get<T>();
    _dependencieServices[T] = service;
    if (service is MvcService) {
      service._updateDependencies(this);
    }
    return service;
  }

  /// see the [MvcContext.tryDependOnService]
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
  bool get isUpdaterQueryerBreaker => (state as MvcWidgetState?)?.isUpdaterQueryerBreaker ?? super.isUpdaterQueryerBreaker;

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
  /// the nearest [Mvc]'s controller in this context if of type [TControllerType]
  TControllerType get controller => getService();

  /// Whether to allow queries from superiors to continue looking for children
  bool get isUpdaterQueryerBreaker => false;
  @override
  MvcContext<TControllerType> get context => super.context as MvcContext<TControllerType>;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
  }

  /// you can be inject some services here when [ServiceProvider] is created
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
    final _InheritedMvcOwner? inheritedServiceProvider = context.getElementForInheritedWidgetOfExactType<_InheritedMvcOwner>()?.widget as _InheritedMvcOwner?;
    return inheritedServiceProvider?.owner;
  }
}

/// With the service get power to update [MvcServiceScope]
mixin MvcService on DependencyInjectionService {
  late final Set<MvcWidgetElement> _dependents = <MvcWidgetElement>{};

  /// update all [MvcWidget] that depend on this service
  void update([void Function()? fn]) {
    fn?.call();
    for (var element in _dependents) {
      element.markNeedsBuild();
    }
  }

  void _updateDependencies(MvcWidgetElement element) {
    _dependents.add(element);
  }

  /// Update the child [MvcWidget] that depend on this service
  void updateWidget<T extends MvcWidget>() => _find(MvcUpdaterQueryPredicate.makeWithWidgetType(T)).update();

  /// Update the child [MvcWidget] that depend on [T] that depend on this service
  void updateService<T extends Object>() => _find(MvcUpdaterQueryPredicate.makeWithServiceType(T)).update();

  /// find and update the child [MvcWidget] that depend on this service
  Iterable<MvcWidgetUpdater> $<T extends MvcWidget>([String? q]) sync* {
    for (var element in _dependents) {
      yield* element._widgetManager.query(MvcUpdaterQueryPredicate.makeWithQuery(q ?? T.toString()));
    }
  }

  Iterable<MvcWidgetUpdater> _find(MvcUpdaterQueryPredicate predicate) {
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

/// it's can to found [MvcWidget]
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

  bool isMatch(MvcUpdaterQueryPredicate predicate) {
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

  Iterable<MvcWidgetUpdater> query(MvcUpdaterQueryPredicate predicate) sync* {
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

/// just as root element for [MvcWidget], provider root [ServiceProvider]
class MvcApp extends StatefulWidget {
  const MvcApp({required this.child, this.owner, super.key});
  final MvcOwner? owner;
  final Widget child;

  @override
  State<MvcApp> createState() => _MvcAppState();
}

class _InheritedMvcOwner extends InheritedWidget {
  const _InheritedMvcOwner({required this.owner, required super.child});
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

    return _InheritedMvcOwner(
      owner: owner,
      child: Mvc<MvcOwner, Widget>(
        create: () => owner,
        model: widget.child,
      ),
    );
  }
}
