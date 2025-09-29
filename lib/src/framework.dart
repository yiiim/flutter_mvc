import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';

MvcStoreUseful getStore(BuildContext context) {
  return context.getMvcService<MvcStoreUseful>()..setUpBeforUse(context);
}

void createState<T, R extends MvcRawStore<T>>(
  BuildContext context,
  T state,
) {
  final repository = context.getMvcService<MvcStoreRespositiory>();
  final store = MvcRawStore<T>(state);
  repository.addStore<T, R>(store as R);
}

/// Mvc framework context
///
/// This is the [MvcWidget]'s context, can be get in [MvcStatelessWidget.build] method or [MvcWidgetState.context].
abstract class MvcContext extends BuildContext implements MvcWidgetSelector {}

/// Mvc framework widget
///
/// Don't use this class directly, use [MvcStatelessWidget] or [MvcStatefulWidget] instead.
///
/// Can be update by [MvcController.querySelectorAll] if extends [MvcStatelessWidget] or [MvcStatefulWidget].
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
///     querySelectorAll<MyWidget>().update(() => title = "MyWidget Title Updated");
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
/// Also can be update by [MvcController.querySelectorAll] if [MvcWidget.id] or [MvcWidget.classes] be set.
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
///     querySelectorAll("#my-widget").update(() => title = "MyWidget Title Updated");; // or querySelectorAll(".my-widget").update(() => title = "MyWidget Title Updated");;
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
abstract class MvcWidget implements Widget {
  String? get id;
  List<String>? get classes;
  Map<Object, String>? get attributes;
}

/// Mvc framework stateless widget
///
/// [build] method context can cast to [MvcContext]
///
/// About how to update this widget, see [MvcWidget]
abstract class MvcStatelessWidget extends StatelessWidget implements MvcWidget {
  const MvcStatelessWidget({this.id, this.classes, this.attributes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;
  @override
  final Map<Object, String>? attributes;

  @override
  StatelessElement createElement() => MvcStatelessElement(this);
}

/// Mvc framework stateful widget
///
/// About how to update this widget, see [MvcWidget]
abstract class MvcStatefulWidget extends StatefulWidget implements MvcWidget {
  const MvcStatefulWidget({this.id, this.classes, this.attributes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;
  @override
  final Map<Object, String>? attributes;

  @override
  StatefulElement createElement() => MvcStatefulElement(this);

  @override
  MvcWidgetState<MvcStatefulWidget> createState();
}

abstract class _MvcServiceProviderSetUpWidget {
  ServiceProvider? get serviceProvider;
}

class _InheritedServiceProvider extends InheritedWidget {
  const _InheritedServiceProvider({required this.serviceProvider, required super.child});
  final ServiceProvider serviceProvider;
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is! _InheritedServiceProvider || oldWidget.serviceProvider != serviceProvider;
  }

  static ServiceProvider? of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_InheritedServiceProvider>()?.serviceProvider;
  }
}

/// We can use [MvcApp] to provide initial services.
class MvcApp extends InheritedWidget implements _MvcServiceProviderSetUpWidget {
  const MvcApp({
    this.serviceProvider,
    required super.child,
    super.key,
  });
  @override
  final ServiceProvider? serviceProvider;

  @override
  InheritedElement createElement() => _MvcAppElement(this);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _MvcServiceAspect {
  _MvcServiceAspect(this.service, {this.aspect});
  final MvcDependentObject service;
  final Object? aspect;

  @override
  bool operator ==(Object other) => other is _MvcServiceAspect && other.service == service && other.aspect == aspect;

  @override
  int get hashCode => service.hashCode ^ (aspect?.hashCode ?? 0);
}

class _MvcAppElement extends InheritedElement {
  _MvcAppElement(MvcApp widget) : super(widget);
  @override
  void updateDependencies(Element dependent, Object? aspect) {
    WidgetsFlutterBinding.ensureInitialized();
    final Set<_MvcServiceAspect>? dependencies = getDependencies(dependent) as Set<_MvcServiceAspect>?;
    if (dependencies != null && dependencies.isEmpty) {
      return;
    }
    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcServiceAspect>());
    } else {
      assert(aspect is _MvcServiceAspect);
      _MvcServiceAspect serviceAspect = aspect as _MvcServiceAspect;
      serviceAspect.service.updateDependencies(dependent);
      setDependencies(dependent, (dependencies ?? HashSet<_MvcServiceAspect>())..add(serviceAspect));
    }
  }

  @override
  void removeDependent(Element dependent) {
    final Set<MvcDependentObject>? dependencies = (getDependencies(dependent) as Set<_MvcServiceAspect>?)
        ?.map(
          (e) => e.service,
        )
        .toSet();
    if (dependencies != null) {
      for (var element in dependencies) {
        element.removeDependencies(dependent);
      }
    }
    super.removeDependent(dependent);
  }

  @override
  Widget build() {
    return _InheritedServiceProvider(
      serviceProvider: (widget as MvcApp).serviceProvider ?? ServiceCollection().build(),
      child: MvcDependencyProvider(
        provider: (collection) {
          collection.add<MvcStoreUseful>((_) => MvcStoreUseful());
        },
        child: MvcStateScope(
          builder: (context) {
            return super.build();
          },
        ),
      ),
    );
  }

  void clearObjectDependencies(Element dependent) {
    setDependencies(dependent, null);
  }
}

mixin MvcBasicElement on ComponentElement, DependencyInjectionService {
  ServiceProvider? scopedServiceProvider;

  bool get createStateScope => true;

  @override
  void mount(Element? parent, Object? newSlot) {
    ServiceProvider? parentServiceProvider;
    if (widget is _MvcServiceProviderSetUpWidget) {
      parentServiceProvider = (widget as _MvcServiceProviderSetUpWidget).serviceProvider;
    } else if (parent != null) {
      parentServiceProvider = _InheritedServiceProvider.of(parent);
    }
    if (parentServiceProvider != null) {
      scopedServiceProvider = parentServiceProvider.buildScoped(
        builder: (collection) {
          initServices(collection, parentServiceProvider);
        },
      );
    } else {
      ServiceCollection collection = ServiceCollection();
      initServices(collection, null);
      scopedServiceProvider = collection.build();
    }
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    super.unmount();
    dispose();
  }

  @override
  void activate() {
    super.activate();
    ServiceProvider? parentServiceProvider;
    if (widget is _MvcServiceProviderSetUpWidget) {
      parentServiceProvider = (widget as _MvcServiceProviderSetUpWidget).serviceProvider;
    } else {
      parentServiceProvider = _InheritedServiceProvider.of(this);
    }
    assert(parentServiceProvider != null);
    scopedServiceProvider!.transferScope(parentServiceProvider);
  }

  @override
  Widget build() {
    return _InheritedServiceProvider(
      serviceProvider: serviceProvider,
      child: super.build(),
    );
  }

  @mustCallSuper
  @protected
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    collection.addSingleton<MvcBasicElement>(
      (serviceProvider) => this,
      initializeWhenServiceProviderBuilt: true,
    );
    if (createStateScope) {
      collection.addSingleton<MvcStoreRespositiory>(
        (serviceProvider) => MvcStoreRespositiory._internal(
          parent?.tryGet<MvcStoreRespositiory>(),
        ),
        initializeWhenServiceProviderBuilt: true,
      );
    }
  }
}

/// mvc framework stateless element
class MvcStatelessElement<TControllerType extends MvcController> extends StatelessElement with DependencyInjectionService, MvcBasicElement, MvcNodeMixin {
  MvcStatelessElement(MvcStatelessWidget widget) : super(widget);
}

/// mvc framework stateful element
class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with DependencyInjectionService, MvcBasicElement, MvcNodeMixin {
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget);
  @override
  bool get createStateScope => (state as MvcWidgetState).createStateScope;
  @override
  bool get isSelectorBreaker => (state as MvcWidgetState).isSelectorBreaker;

  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
    (state as MvcWidgetState?)?.initServices(collection, parent);
  }
}

mixin _DisposeHelper<T extends StatefulWidget> on State<T> {
  void _dispose() => super.dispose();
}

abstract class MvcWidgetState<T extends MvcStatefulWidget> extends State<T> with _DisposeHelper, DependencyInjectionService implements MvcWidgetSelector {
  bool get createStateScope => false;

  /// Whether to allow queries from superiors to continue looking for children
  bool get isSelectorBreaker => false;
  @override
  MvcContext get context => super.context as MvcContext;

  /// you can be inject some services here when [ServiceProvider] is created
  @mustCallSuper
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    collection.addSingleton<MvcWidgetState>(
      (serviceProvider) => this,
      initializeWhenServiceProviderBuilt: true,
    );
  }

  @mustCallSuper
  @override
  void dispose() {
    if (mounted) _dispose();
    super.dispose();
  }

  @override
  Iterable<MvcWidgetUpdater> querySelectorAll<E>([String? selectors, bool ignoreSelectorBreaker = false]) => context.querySelectorAll<E>(selectors, ignoreSelectorBreaker);
  @override
  MvcWidgetUpdater? querySelector<E>([String? selectors, bool ignoreSelectorBreaker = false]) => context.querySelector<E>(selectors, ignoreSelectorBreaker);
}

class MvcDependencyProvider extends MvcStatefulWidget {
  const MvcDependencyProvider({required this.child, required this.provider, super.key});
  final void Function(ServiceCollection collection)? provider;
  final Widget child;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _MvcDependencyProviderState();
}

class _MvcDependencyProviderState extends MvcWidgetState<MvcDependencyProvider> {
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

mixin MvcDependentObject {
  final Map<Element, Object?> _dependents = HashMap<Element, Object?>();

  /// update all [MvcWidget] that depend on this service
  void update([void Function()? fn]) {
    fn?.call();
    notifyDependents();
  }

  @protected
  Object? getDependencies(Element dependent) {
    return _dependents[dependent];
  }

  @protected
  void setDependencies(Element dependent, Object? value) {
    _dependents[dependent] = value;
  }

  @protected
  void updateDependencies(Element dependent, {Object? aspect}) {
    setDependencies(dependent, null);
  }

  @protected
  void removeDependencies(Element element) {
    _dependents.remove(element);
  }

  @protected
  void notifyDependent(Element dependent, {Object? aspect}) {
    dependent.markNeedsBuild();
  }

  @protected
  bool shouldNotifyDependents(Element dependent, {Object? aspect}) {
    return true;
  }

  @protected
  void notifyDependents() {
    for (var element in _dependents.entries) {
      if (shouldNotifyDependents(element.key, aspect: element.value)) {
        notifyDependent(element.key, aspect: element.value);
      }
    }
  }
}

class _MvcStateStoreAspect<T, R> {
  _MvcStateStoreAspect({required this.selector, required this.value});
  final R Function(T state) selector;
  final R value;

  @override
  bool operator ==(Object other) => other is _MvcStateStoreAspect && other.selector == selector && other.value == value;

  @override
  int get hashCode => selector.hashCode ^ value.hashCode;
}

class MvcRawStore<T> with MvcDependentObject {
  final T state;

  MvcRawStore(this.state);

  @override
  void updateDependencies(Element dependent, {Object? aspect}) {
    final Set<_MvcStateStoreAspect>? dependencies = getDependencies(dependent) as Set<_MvcStateStoreAspect>?;
    if (dependencies != null && dependencies.isEmpty) {
      return;
    }

    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcStateStoreAspect>());
    } else {
      assert(aspect is _MvcStateStoreAspect);
      setDependencies(dependent, (dependencies ?? HashSet<_MvcStateStoreAspect>())..add(aspect as _MvcStateStoreAspect));
    }
  }

  @override
  bool shouldNotifyDependents(Element dependent, {Object? aspect}) {
    final Set<_MvcStateStoreAspect>? dependencies = getDependencies(dependent) as Set<_MvcStateStoreAspect>?;
    if (dependencies == null) {
      return false;
    }
    for (var element in dependencies) {
      if (element.selector(state) != element.value) {
        return true;
      }
    }
    return false;
  }

  R useState<R>(BuildContext context, [R Function(T state)? use]) {
    assert(context.debugDoingBuild, 'can only be called during build');
    final value = use?.call(state) ?? state;
    context.dependOnMvcService(
      this,
      aspect: _MvcStateStoreAspect<T, R>(selector: use ?? (s) => s as R, value: value as R),
    );
    return value;
  }

  void setState(void Function(T state) set) {
    update(
      () {
        set(state);
      },
    );
  }
}

final class MvcStoreRespositiory with DependencyInjectionService {
  MvcStoreRespositiory._internal(this.parent);
  MvcStoreRespositiory? parent;
  final Map<Type, MvcRawStore> stores = {};
  R? getStore<T, R extends MvcRawStore<T>>() {
    return stores[T] as R? ?? parent?.getStore<T, R>();
  }

  void addStore<T, R extends MvcRawStore<T>>(R store) {
    assert(!stores.containsKey(T), "state $T already exists");
    stores[T] = store;
  }
}

class MvcStateScope extends MvcStatefulWidget {
  const MvcStateScope({required this.builder, super.key});
  final WidgetBuilder builder;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _MvcStateScopeState();
}

class _MvcStateScopeState extends MvcWidgetState<MvcStatefulWidget> {
  @override
  bool get createStateScope => true;

  @override
  Widget build(BuildContext context) {
    return (widget as MvcStateScope).builder(context);
  }
}

class MvcStoreUseful with DependencyInjectionService, MvcDependentObject {
  BuildContext? _context;
  void setUpBeforUse(BuildContext context) {
    assert(_context!.debugDoingBuild, 'can only be called during build');
    final _MvcAppElement element = context.getElementForInheritedWidgetOfExactType<MvcApp>() as _MvcAppElement;
    element.clearObjectDependencies(context as Element);
    _context = context;
  }

  R useState<T, R>(R Function(T use) fn) {
    assert(_context != null, "please call setUpBeforUse(context) before useState");
    return useStateOfExactRawStoreType<T, R, MvcRawStore<T>>(fn);
  }

  R useStateOfExactRawStoreType<T, R, E extends MvcRawStore<T>>(R Function(T use) fn) {
    final store = getService<MvcStoreRespositiory>().getStore<T, E>();
    assert(store != null, "can't find state $T in context");
    return useStateOfExactRawStore<T, R, E>(store!, fn);
  }

  R useStateOfExactRawStore<T, R, E extends MvcRawStore<T>>(E store, R Function(T use) fn) {
    assert(_context != null, "please call setUpBeforUse(context) before useState");
    assert(_context!.debugDoingBuild, 'can only be called during build');
    return store.useState(_context!, fn);
  }
}

class MvcUseState extends MvcStatelessWidget {
  const MvcUseState({
    super.key,
    required this.builder,
  });
  final Widget Function(MvcStoreUseful useState) builder;

  @override
  Widget build(BuildContext context) {
    final storeUseful = context.getMvcService<MvcStoreUseful>();
    storeUseful.setUpBeforUse(context);
    return builder(storeUseful);
  }
}

extension MvcServicesExtension on BuildContext {
  T getMvcService<T extends Object>() {
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).getService<T>();
    }
    return _InheritedServiceProvider.of(this)!.get<T>();
  }

  T? tryGetMvcService<T extends Object>() {
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).tryGetService<T>();
    }
    return _InheritedServiceProvider.of(this)?.tryGet<T>();
  }

  T dependOnMvcServiceOfExactType<T extends MvcDependentObject>({Object? aspect}) {
    var service = getMvcService<T>();
    dependOnMvcService(
      service,
      aspect: aspect,
    );
    return service;
  }

  T? tryDependOnMvcServiceOfExactType<T extends MvcDependentObject>({Object? aspect}) {
    var service = tryGetMvcService<T>();
    if (service != null) {
      dependOnMvcService(
        service,
        aspect: aspect,
      );
    }
    return service;
  }

  void dependOnMvcService(MvcDependentObject service, {Object? aspect}) {
    dependOnInheritedWidgetOfExactType<MvcApp>(aspect: _MvcServiceAspect(service, aspect: aspect));
  }
}

extension MvcService on DependencyInjectionService {
  R createState<T, R extends MvcRawStore<T>>(
    T state, {
    R Function(T state)? initializer,
  }) {
    final repository = getService<MvcStoreRespositiory>();
    final store = initializer?.call(state) ?? MvcRawStore<T>(state);
    repository.addStore<T, R>(store as R);
    return store;
  }
}
