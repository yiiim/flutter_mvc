import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';

typedef MvcSetState<T> = void Function(Function(T state));

/// A base class for widgets in the MVC framework.
///
/// Do not use this class directly. Instead, use [MvcStatelessWidget] or [MvcStatefulWidget].
///
/// Widgets extending [MvcStatelessWidget] or [MvcStatefulWidget] can be updated
/// via [MvcController.querySelectorAll].
///
/// Example of updating by type:
/// ```dart
/// String text = "Initial Text";
/// class MyWidget extends MvcStatelessWidget {
///   const MyWidget({super.key, super.id, super.classes, super.attributes});
///   @override
///   Widget build(BuildContext context) {
///     return Text(text);
///   }
/// }
///
/// // In the controller:
/// class MyController extends MvcController {
///   void updateMyWidget() {
///     // This will find all MyWidget instances and trigger their rebuild.
///     text = "Updated Text";
///     querySelectorAll<MyWidget>().update();
///   }
/// }
/// ```
///
/// Widgets can also be targeted by `id` or `classes`.
///
/// Example of updating by selector:
/// ```dart
/// // In the view:
/// class MyView extends MvcView {
///   @override
///   Widget build(BuildContext context) {
///     return MyWidget(id: "my-widget", classes: ["my-class"]);
///   }
/// }
///
/// // In the controller:
/// class MyController extends MvcController {
///   void updateMyWidget() {
///     // Query by ID
///     querySelector("#my-widget")?.update();
///     // Or query by class
///     querySelectorAll(".my-class").update();
///   }
/// }
/// ```
abstract class MvcWidget implements Widget {
  /// A unique identifier for the widget, used for selector queries.
  String? get id;

  /// A list of class names for the widget, used for selector queries.
  List<String>? get classes;

  /// A map of attributes for the widget, used for attribute-based selector queries.
  Map<Object, String>? get attributes;
}

/// A stateless widget for the MVC framework.
///
/// For details on how to update this widget, see [MvcWidget].
abstract class MvcStatelessWidget extends StatelessWidget implements MvcWidget {
  /// Creates an [MvcStatelessWidget].
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

/// A stateful widget for the MVC framework.
///
/// For details on how to update this widget, see [MvcWidget].
abstract class MvcStatefulWidget extends StatefulWidget implements MvcWidget {
  /// Creates an [MvcStatefulWidget].
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

/// The root widget for an MVC application.
///
/// It sets up the root dependency injection scope and other essential services
/// for the framework. Every application using `flutter_mvc` should have an
/// [MvcApp] at the root of its widget tree.
///
/// ```dart
/// void main() {
///   runApp(
///     MaterialApp(
///       home: MvcApp(
///         serviceProviderBuilder: (collection) {
///           collection.addSingleton<MyService>((_) => MyService());
///         },
///         child: MyHomeScreen(),
///       ),
///     ),
///   );
/// }
/// ```
class MvcApp extends StatelessWidget {
  /// Creates the root widget for an MVC application.
  const MvcApp({
    required this.child,
    this.serviceProvider,
    this.serviceProviderBuilder,
    super.key,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// An optional pre-built [ServiceProvider]. If provided, it will be used as the root
  /// service provider.
  final ServiceProvider? serviceProvider;

  /// A builder function to register services in the root scope.
  final void Function(ServiceCollection collection)? serviceProviderBuilder;
  static bool _debugHasMvcApp(BuildContext? context) {
    assert(() {
      if (context?.getElementForInheritedWidgetOfExactType<_MvcApp>() == null) {
        return false;
      }
      return true;
    }(), 'No MvcApp found.');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _MvcApp(
      serviceProvider: serviceProvider,
      serviceProviderBuilder: serviceProviderBuilder,
      child: child,
    );
  }
}

class _MvcApp extends InheritedWidget {
  const _MvcApp({
    this.serviceProvider,
    this.serviceProviderBuilder,
    required super.child,
  });
  final ServiceProvider? serviceProvider;
  final void Function(ServiceCollection collection)? serviceProviderBuilder;
  @override
  InheritedElement createElement() => _MvcAppElement(this);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _MvcDependentObjectAspect {
  _MvcDependentObjectAspect(this.service, {this.aspect});
  final MvcDependableObject service;
  final Object? aspect;

  @override
  bool operator ==(Object other) => other is _MvcDependentObjectAspect && other.service == service && other.aspect == aspect;

  @override
  int get hashCode => service.hashCode ^ (aspect?.hashCode ?? 0);
}

class _MvcAppElement extends InheritedElement {
  _MvcAppElement(_MvcApp widget) : super(widget);
  ServiceProvider? _serviceProvider;
  @override
  void mount(Element? parent, Object? newSlot) {
    _initServiceProvider(widget as _MvcApp);
    super.mount(parent, newSlot);
  }

  @override
  void update(covariant ProxyWidget newWidget) {
    final newMvcAppWidget = newWidget as _MvcApp;
    if (newMvcAppWidget.serviceProviderBuilder != (widget as _MvcApp).serviceProviderBuilder || newMvcAppWidget.serviceProvider != (widget as _MvcApp).serviceProvider) {
      _initServiceProvider(newMvcAppWidget);
    }
    super.update(newWidget);
  }

  @override
  void unmount() {
    _serviceProvider?.dispose();
    _serviceProvider = null;
    super.unmount();
  }

  void _initServiceProvider(_MvcApp widget) {
    _serviceProvider?.dispose();
    _serviceProvider = (widget.serviceProvider ?? ServiceCollection().build()).buildScoped(
      builder: (collection) {
        widget.serviceProviderBuilder?.call(collection);
        collection.add<MvcStateAccessor>((_) => MvcStateAccessor());
        collection.addScopedSingleton(
          (_) => MvcWidgetScope(),
        );
        collection.addSingleton<_MvcAppElement>(
          (_) => this,
        );
        collection.addSingleton<_MvcStoreRepository>(
          (_) => _MvcStoreRepository._internal(null),
        );
        collection.addSingleton<MvcStateScope>(
          (serviceProvider) => serviceProvider.get<_MvcStoreRepository>(),
        );
      },
    );
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final Set<_MvcDependentObjectAspect>? dependencies = getDependencies(dependent) as Set<_MvcDependentObjectAspect>?;
    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcDependentObjectAspect>());
    } else {
      assert(aspect is _MvcDependentObjectAspect);
      _MvcDependentObjectAspect serviceAspect = aspect as _MvcDependentObjectAspect;
      serviceAspect.service.updateDependencies(_MvcDependableElementListener(dependent), aspect: serviceAspect.aspect);
      setDependencies(dependent, (dependencies ?? HashSet<_MvcDependentObjectAspect>())..add(serviceAspect));
    }
  }

  @override
  void removeDependent(Element dependent) {
    final Set<MvcDependableObject>? dependencies = (getDependencies(dependent) as Set<_MvcDependentObjectAspect>?)
        ?.map(
          (e) => e.service,
        )
        .toSet();
    if (dependencies != null) {
      for (var element in dependencies) {
        element.removeDependencies(_MvcDependableElementListener(dependent));
      }
    }
    super.removeDependent(dependent);
  }

  @override
  Widget build() {
    return _InheritedServiceProvider(
      serviceProvider: _serviceProvider!,
      child: Builder(
        builder: (context) {
          return MvcStateScopeBuilder(builder: (_) => super.build());
        },
      ),
    );
  }

  void clearObjectDependencies(Element dependent) {
    removeDependent(dependent);
  }
}

/// A mixin for `Element`s that provides basic MVC framework functionalities,
/// including dependency injection scope management.
mixin MvcBasicElement on ComponentElement, DependencyInjectionService implements MvcWidgetSelector {
  ServiceProvider? scopedServiceProvider;

  /// Determines whether this element creates a new state scope.
  bool get createStateScope => false;
  MvcWidgetScope? _widgetScope;
  MvcWidgetScope get widgetScope {
    assert(scopedServiceProvider != null, 'use after mount');
    _widgetScope ??= scopedServiceProvider!.get<MvcWidgetScope>();
    return _widgetScope!;
  }

  MvcStateScope? _stateScope;
  MvcStateScope get stateScope {
    assert(scopedServiceProvider != null, 'use after mount');
    _stateScope ??= scopedServiceProvider!.get<MvcStateScope>();
    return _stateScope!;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(widget is MvcWidget);
    assert(MvcApp._debugHasMvcApp(parent));
    ServiceProvider? parentServiceProvider = _InheritedServiceProvider.of(parent!);
    assert(
      () {
        if (parentServiceProvider == null) {
          return false;
        }
        if (parentServiceProvider.tryGet<_MvcAppElement>() == null) {
          return false;
        }
        return true;
      }(),
      "No ServiceProvider found in context. Make sure MvcApp is at the root of the widget tree.",
    );
    scopedServiceProvider = parentServiceProvider!.buildScoped(
      builder: (collection) {
        initServices(collection, parentServiceProvider);
      },
    );
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    super.unmount();
    dispose();
  }

  @override
  void dispose() {
    super.dispose();
    scopedServiceProvider?.dispose();
  }

  @override
  void activate() {
    super.activate();
    ServiceProvider? parentServiceProvider;
    parentServiceProvider = _InheritedServiceProvider.of(this);
    assert(
      () {
        if (parentServiceProvider == null) {
          return false;
        }
        if (parentServiceProvider.tryGet<_MvcAppElement>() == null) {
          return false;
        }
        return true;
      }(),
      "No ServiceProvider found in context. Make sure MvcApp is at the root of the widget tree.",
    );
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
      collection.addSingleton<_MvcStoreRepository>(
        (serviceProvider) => _MvcStoreRepository._internal(
          parent!.get<_MvcStoreRepository>(),
        ),
        initializeWhenServiceProviderBuilt: true,
      );
      collection.addSingleton<MvcStateScope>(
        (serviceProvider) => serviceProvider.get<_MvcStoreRepository>(),
      );
    }
  }
}

/// mvc framework stateless element
class MvcStatelessElement<TControllerType extends MvcController> extends StatelessElement with DependencyInjectionService, MvcBasicElement, MvcNodeMixin {
  /// Creates an element for the given [MvcStatelessWidget].
  MvcStatelessElement(MvcStatelessWidget widget) : super(widget);
}

/// The element for an [MvcStatefulWidget].
class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with DependencyInjectionService, MvcBasicElement, MvcNodeMixin {
  /// Creates an element for the given [MvcStatefulWidget].
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget);
  @override
  bool get createStateScope => (state as MvcWidgetState).createStateScope;
  @override
  bool get isSelectorBreaker => (state as MvcWidgetState).isSelectorBreaker;
  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    (state as MvcWidgetState?)?.initServices(collection, parent);
    super.initServices(collection, parent);
  }
}

mixin _DisposeHelper<T extends StatefulWidget> on State<T> {
  void _dispose() => super.dispose();
}

/// The base class for the `State` of an [MvcStatefulWidget].
///
/// It provides access to the [MvcContext] and lifecycle methods for service initialization.
abstract class MvcWidgetState<T extends MvcStatefulWidget> extends State<T> with _DisposeHelper, DependencyInjectionService implements MvcWidgetSelector {
  /// Determines whether this state's widget creates a new state scope.
  /// Defaults to `false`.
  bool get createStateScope => false;

  /// Whether to break the propagation of selector queries from parent widgets.
  /// If `true`, queries will not search children of this widget.
  /// Defaults to `false`.
  bool get isSelectorBreaker => false;

  /// The [MvcWidgetScope] associated with this widget.
  MvcWidgetScope get widgetScope => (context as MvcBasicElement).widgetScope;

  /// The [MvcStateScope] associated with this widget.
  MvcStateScope get stateScope => (context as MvcBasicElement).stateScope;

  /// Called when the [ServiceProvider] is created, allowing for service injection.
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
  Iterable<MvcWidgetScope> querySelectorAll<E>([String? selectors, bool ignoreSelectorBreaker = false]) => widgetScope.querySelectorAll<E>(selectors, ignoreSelectorBreaker);
  @override
  MvcWidgetScope? querySelector<E>([String? selectors, bool ignoreSelectorBreaker = false]) => widgetScope.querySelector<E>(selectors, ignoreSelectorBreaker);
}


/// Provides the ability to interact with a specific [MvcWidget] instance,
/// including accessing its context, triggering rebuilds, and querying other widgets.
///
/// Every `MvcWidget` (i.e., [MvcStatelessWidget], [MvcStatefulWidget], [Mvc], etc.)
/// has a corresponding [MvcWidgetScope].
///
/// ### How to Obtain
/// - In an [MvcController] or [MvcWidgetState], you can directly access it through
///   the `widgetScope` property.
/// - By getting an instance of type [MvcWidgetScope] through dependency injection.
///   When using dependency injection, be mindful of the scope rules to ensure you
///   get the instance from the correct scope.
final class MvcWidgetScope with DependencyInjectionService {
  late final MvcBasicElement _element;

  /// The [BuildContext] of the associated widget.
  BuildContext get context {
    return _element;
  }

  /// Marks the associated widget as needing to be rebuilt.
  ///
  /// The optional [fn] callback will be executed before marking the widget for rebuild.
  /// This is useful for making state changes that should be reflected in the UI.
  ///
  /// ```dart
  /// // In a controller:
  /// void refreshWidget() {
  ///   widgetScope.update(() {
  ///     // Update state here
  ///   });
  /// }
  /// ```
  void update([VoidCallback? fn]) {
    fn?.call();
    _element.markNeedsBuild();
  }

  /// Finds all descendant [MvcWidget]s that match the given [selectors].
  ///
  /// You can use a querySelectorAll-like syntax from the W3C standard to query Widgets.
  /// Sibling lookups are not supported.
  ///
  /// When you provide a type [T], it is used as a type selector, equivalent to
  /// prepending the type name to the [selectors] string.
  ///
  /// [ignoreSelectorBreaker] allows the query to bypass widgets that would normally
  /// stop selector propagation (i.e., where `isSelectorBreaker` is true).
  ///
  /// Example:
  /// ```dart
  /// // Find all MyItemWidget widgets with the class 'highlight'
  /// context.querySelectorAll<MyItemWidget>('.highlight');
  /// ```
  Iterable<MvcWidgetScope> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]) {
    return _element.querySelectorAll<T>(selectors, ignoreSelectorBreaker);
  }

  /// Finds the first descendant [MvcWidget] that matches the given [selectors].
  ///
  /// See [querySelectorAll] for more details on selectors.
  MvcWidgetScope? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]) {
    return _element.querySelector<T>(selectors, ignoreSelectorBreaker);
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    final element = tryGetService<MvcBasicElement>();
    assert(element != null, "can't find MvcWidget in context");
    _element = element!;
  }
}

class MvcWidgetScopeBuilder extends MvcStatefulWidget {
  const MvcWidgetScopeBuilder({super.key, super.classes, super.id, super.attributes, required this.builder, this.onWidgetScopeCreated});
  final Widget Function(BuildContext context) builder;
  final void Function(MvcWidgetScope scope)? onWidgetScopeCreated;
  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _MvcWidgetScopeBuilderState();
}

class _MvcWidgetScopeBuilderState extends MvcWidgetState<MvcWidgetScopeBuilder> {
  @override
  void initState() {
    super.initState();
    widget.onWidgetScopeCreated?.call(widgetScope);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// A widget that provides a dependency injection scope to its descendants.
///
/// Services registered via [provider] are available to all descendant widgets.
class MvcDependencyProvider extends MvcStatefulWidget {
  /// Creates a dependency provider widget.
  const MvcDependencyProvider({required this.child, required this.provider, super.key});

  /// The function to register services.
  final void Function(ServiceCollection collection)? provider;

  /// The widget below this widget in the tree.
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

/// An interface for listeners that can be notified of changes in a [MvcDependableObject].
abstract class MvcDependableListener {
  /// Called when the dependency has changed.
  /// [aspect] can provide more specific information about the change.
  void onDependencyChanged(Object? aspect);
}

/// A function-based implementation of [MvcDependableListener].
class MvcDependableFunctionListener extends MvcDependableListener {
  /// Creates a listener from a function.
  MvcDependableFunctionListener(this.listener);

  /// The function to call on dependency change.
  final void Function(Object? aspect) listener;
  @override
  void onDependencyChanged(Object? aspect) {
    listener(aspect);
  }
}

class _MvcDependableElementListener extends MvcDependableListener {
  _MvcDependableElementListener(this.element);
  final Element element;
  @override
  void onDependencyChanged(Object? aspect) {
    element.markNeedsBuild();
  }

  @override
  bool operator ==(Object other) => other is _MvcDependableElementListener && other.element == element;

  @override
  int get hashCode => element.hashCode;
}

abstract class MvcStateListener {
  void onMvcStateChanged(Object state);
}

class _MvcDependableStateListener<T extends Object, R> extends MvcDependableListener {
  _MvcDependableStateListener({
    required this.store,
    required this.listener,
    this.selector,
  });
  final MvcRawStore<T> store;
  final MvcStateListener listener;
  final R Function(T state)? selector;
  @override
  void onDependencyChanged(Object? aspect) {
    listener.onMvcStateChanged(store.state);
  }
}

/// A mixin for objects that can be depended upon by widgets.
///
/// When the object changes, it can notify its dependents to rebuild.
/// This is the foundation for reactive state management in the framework.
mixin MvcDependableObject {
  final Map<MvcDependableListener, Object?> _dependents = HashMap<MvcDependableListener, Object?>();

  /// Gets the dependency aspect for a given listener.
  @protected
  Object? getDependencies(MvcDependableListener dependent) {
    return _dependents[dependent];
  }

  /// Sets the dependency aspect for a given listener.
  @protected
  void setDependencies(MvcDependableListener dependent, Object? value) {
    _dependents[dependent] = value;
  }

  /// Updates the dependencies for a listener.
  @protected
  void updateDependencies(MvcDependableListener dependent, {Object? aspect}) {
    setDependencies(dependent, aspect);
  }

  /// Removes a dependent listener.
  @protected
  void removeDependencies(MvcDependableListener element) {
    _dependents.remove(element);
  }

  @protected
  void removeWhere(bool Function(MvcDependableListener dependent, Object? aspect) test) {
    final toRemove = _dependents.entries.where((entry) => test(entry.key, entry.value)).map((entry) => entry.key).toList();
    for (var element in toRemove) {
      removeDependencies(element);
    }
  }

  /// Notifies a specific dependent of a change.
  @protected
  void notifyDependent(MvcDependableListener dependent, {Object? aspect}) {
    dependent.onDependencyChanged(aspect);
  }

  /// Determines if a dependent should be notified of a change.
  @protected
  bool shouldNotifyDependents(MvcDependableListener dependent, {Object? aspect}) {
    return true;
  }

  /// Notifies all dependents of a change.
  @protected
  void notifyAllDependents() {
    for (var element in _dependents.entries) {
      if (shouldNotifyDependents(element.key, aspect: element.value)) {
        notifyDependent(element.key, aspect: element.value);
      }
    }
  }
}

class _MvcStateStoreAspect<T, R> {
  _MvcStateStoreAspect({this.selector, required this.value});
  final R Function(T state)? selector;
  final R value;

  @override
  bool operator ==(Object other) => other is _MvcStateStoreAspect<T, R> && other.selector == selector && other.value == value;

  @override
  int get hashCode => selector.hashCode ^ value.hashCode;

  bool shouldNotify(T state) {
    if (selector == null || value == state) {
      return true;
    }
    return selector!.call(state) != value;
  }
}

/// A raw store that holds a state object [T] and manages its dependencies.
///
/// This is the core of the state management system.
class MvcRawStore<T extends Object> with MvcDependableObject {
  /// The state object.
  final T state;

  /// Creates a raw store with the initial state.
  MvcRawStore(this.state);

  @protected
  @override
  void updateDependencies(MvcDependableListener dependent, {Object? aspect}) {
    final Set<_MvcStateStoreAspect>? dependencies = getDependencies(dependent) as Set<_MvcStateStoreAspect>?;
    if (dependencies != null && dependencies.isEmpty) {
      return;
    }

    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcStateStoreAspect>());
    } else {
      assert(aspect is _MvcStateStoreAspect);
      setDependencies(
        dependent,
        (dependencies ?? HashSet<_MvcStateStoreAspect>())..add(aspect as _MvcStateStoreAspect),
      );
    }
  }

  @protected
  @override
  bool shouldNotifyDependents(MvcDependableListener dependent, {Object? aspect}) {
    final Set<_MvcStateStoreAspect>? dependencies = getDependencies(dependent) as Set<_MvcStateStoreAspect>?;
    if (dependencies == null) {
      return false;
    }
    for (var element in dependencies) {
      if (element.shouldNotify(state)) {
        return true;
      }
    }
    return false;
  }

  /// Subscribes the widget to a part of the state.
  ///
  /// When the selected part of the state changes, the widget will rebuild.
  /// The [use] function selects the part of the state to listen to.
  ///
  /// This method must be called within a widget's `build` method.
  R useState<R>(BuildContext context, [R Function(T state)? use]) {
    assert(context.debugDoingBuild, 'can only be called during build');
    final value = use != null ? use(state) : state as R;
    context.dependOnObject(
      this,
      aspect: _MvcStateStoreAspect<T, R>(
        selector: use,
        value: value,
      ),
    );
    return value;
  }

  /// Updates the state and notifies listening widgets.
  ///
  /// The [set] function receives the current state and can modify it.
  void setState([void Function(T state)? set]) {
    set?.call(state);
    notifyAllDependents();
  }

  R listen<R>(MvcStateListener listener, [R Function(T state)? use]) {
    final value = use != null ? use.call(state) : state as R;
    updateDependencies(
      _MvcDependableStateListener(
        store: this,
        listener: listener,
        selector: use,
      ),
      aspect: _MvcStateStoreAspect<T, R>(
        selector: use,
        value: value,
      ),
    );
    return value;
  }

  void removeListener(MvcStateListener listener) {
    removeWhere(
      (dependent, aspect) => dependent is _MvcDependableStateListener && dependent.store == this && dependent.listener == listener,
    );
  }

  void call([void Function(T state)? set]) => setState(set);
}

class _MvcStoreRepository with DependencyInjectionService implements MvcStateScope {
  _MvcStoreRepository._internal(this._parent);
  final _MvcStoreRepository? _parent;
  final Map<Type, MvcRawStore> _stores = {};
  late final Widget? debugWidget;

  void addStore<T extends Object, R extends MvcRawStore<T>>(R store) {
    assert(!_stores.containsKey(T), "state $T already exists");
    _stores[T] = store;
  }

  @override
  MvcSetState<T> createState<T extends Object>(T state) {
    return createStateOfExactStoreType<T, MvcRawStore<T>>(state);
  }

  @override
  MvcSetState<T> createStateIfAbsent<T extends Object>(T Function() initializer) {
    final existingStore = getStoreOfExactType<T, MvcRawStore<T>>();
    if (existingStore != null) {
      return existingStore;
    }
    return createState<T>(initializer());
  }

  R createStateOfExactStoreType<T extends Object, R extends MvcRawStore<T>>(
    T state, {
    R Function(T state)? initializer,
  }) {
    final store = initializer?.call(state) ?? MvcRawStore<T>(state);
    addStore<T, R>(store as R);
    return store;
  }

  @override
  void setState<T extends Object>([void Function(T state)? set]) {
    setStateOfExactStoreType<T, MvcRawStore<T>>(set);
  }

  void setStateOfExactStoreType<T extends Object, E extends MvcRawStore<T>>([void Function(T state)? set]) {
    final store = getStoreOfExactType<T, E>();
    assert(store != null, "can't find state $T in scope");
    store!.setState(set);
  }

  @override
  T? getState<T extends Object>() => getStore<T>()?.state;

  @override
  MvcRawStore<T>? getStore<T extends Object>() {
    return getStoreOfExactType<T, MvcRawStore<T>>();
  }

  @override
  R? getStoreOfExactType<T extends Object, R extends MvcRawStore<T>>() {
    return _stores[T] as R? ?? _parent?.getStoreOfExactType<T, R>();
  }

  @override
  R listenState<T extends Object, R>(MvcStateListener listener, [R Function(T state)? use]) {
    final store = getStore<T>();
    assert(store != null, "can't find state $T in scope");
    return store!.listen<R>(listener, use);
  }

  @override
  void deleteState<T extends Object>() {
    assert(_stores.containsKey(T), "can't find state $T in scope");
    _stores.remove(T);
  }

  @override
  void removeStateListener<T extends Object>(MvcStateListener listener) {
    final store = getStore<T>();
    assert(store != null, "can't find state $T in scope");
    store!.removeListener(listener);
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    assert(() {
      final element = tryGetService<MvcBasicElement>();
      debugWidget = element?.widget;
      return true;
    }());
  }
}

abstract class MvcStateScope {
  /// Creates and registers a new state of type [T].
  /// Throws an error if a state of the same type already exists in the current scope.
  MvcSetState<T> createState<T extends Object>(T state);

  /// If a state of type [T] already exists in the current or parent scope,
  /// returns the [MvcSetState] function for that existing state.
  ///
  /// If no state exists, creates a new state using [initializer] and returns
  /// its [MvcSetState] function.
  MvcSetState<T> createStateIfAbsent<T extends Object>(T Function() initializer);

  /// Updates a state of type [T].
  /// The [set] function receives the current state and can modify it.
  void setState<T extends Object>([void Function(T state)? set]);

  /// Gets the current state of type [T].
  /// Returns `null` if the state does not exist.
  T? getState<T extends Object>();

  /// Gets the raw store for a state of type [T].
  /// Returns `null` if the store does not exist.
  MvcRawStore<T>? getStore<T extends Object>();

  /// A more specific version of [getStore] that allows specifying the exact store type.
  R? getStoreOfExactType<T extends Object, R extends MvcRawStore<T>>();

  /// Deletes a state of type [T] from the current scope.
  void deleteState<T extends Object>();

  /// Listens to changes in a state of type [T] and returns a value of type [R].
  ///
  /// The [listener] is called whenever the selected part of the state changes.
  /// The [use] function selects the part of the state to listen to.
  R listenState<T extends Object, R>(MvcStateListener listener, [R Function(T state)? use]);

  /// Removes a state listener.
  void removeStateListener<T extends Object>(MvcStateListener listener);
}

mixin MvcStatefulService<T extends Object> on DependencyInjectionService {
  late MvcRawStore<T> store;
  T initializeState();

  @protected
  void setState(void Function(T state) set) {
    store.setState(set);
  }

  @mustCallSuper
  @override
  FutureOr dependencyInjectionServiceInitialize() async {
    final storeRepository = tryGetService<_MvcStoreRepository>();
    assert(() {
      assert(storeRepository != null, "use this service in MVC.");
      return true;
    }());
    store = storeRepository!.createStateOfExactStoreType(initializeState());
    return super.dependencyInjectionServiceInitialize();
  }
}

/// A widget that creates a new state scope.
///
/// States created within this scope will not conflict with states of the same
/// type in parent scopes.
class MvcStateScopeBuilder extends MvcStatefulWidget {
  /// Creates a state scope widget.
  const MvcStateScopeBuilder({
    super.key,
    super.classes,
    super.id,
    super.attributes,
    required this.builder,
    this.onStateScopeCreated,
  });

  /// A builder for the child widget.
  final WidgetBuilder builder;

  final void Function(MvcStateScope scope)? onStateScopeCreated;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _MvcStateScopeState();
}

class _MvcStateScopeState extends MvcWidgetState<MvcStateScopeBuilder> {
  @override
  bool get createStateScope => true;

  @override
  void initState() {
    super.initState();
    widget.onStateScopeCreated?.call(stateScope);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// Provides access to the state store for reading and subscribing to state changes.
///
/// This should be used within a widget's `build` method via `context.stateAccessor`.
class MvcStateAccessor with DependencyInjectionService {
  late final _MvcStoreRepository _stateScope = getService<_MvcStoreRepository>();
  BuildContext? _context;
  static final List<BuildContext> _debugStateAccessorContext = [];
  static bool _debugPostFrameClearAccessor = true;
  int _frameNumber = 0;

  /// Prepares the accessor for use within the current build context.
  /// This is called automatically by `context.stateAccessor`.
  void setUpBeforeUse(BuildContext context) {
    assert(_context == null);
    assert(context.debugDoingBuild, 'can only be called during build');
    final _MvcAppElement element = context.getElementForInheritedWidgetOfExactType<_MvcApp>() as _MvcAppElement;
    element.clearObjectDependencies(context as Element);
    assert(
      !_debugStateAccessorContext.contains(this),
      "For the same context, you can only use MvcStateAccessor once per build.",
    );
    assert(() {
      _debugStateAccessorContext.add(context);
      if (_debugPostFrameClearAccessor) {
        _debugPostFrameClearAccessor = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _debugStateAccessorContext.clear();
          _debugPostFrameClearAccessor = true;
        });
      }
      return true;
    }());
    _context = context;
  }

  /// Subscribes to a state of type [T] and returns a value of type [R].
  ///
  /// The [fn] function selects the part of the state to listen to. The widget
  /// will only rebuild if the selected value changes.
  ///
  /// If the state does not exist, [initializer] will be called to create it.
  R useState<T extends Object, R>(R Function(T use) fn, {T Function()? initializer, MvcRawStore<T> Function(T state)? storeInitializer}) {
    return useStateOfExactRawStoreType<T, R, MvcRawStore<T>>(fn, initializer: initializer, storeInitializer: storeInitializer);
  }

  /// A more specific version of [useState] that allows specifying the exact store type.
  R useStateOfExactRawStoreType<T extends Object, R, E extends MvcRawStore<T>>(R Function(T use) fn, {T Function()? initializer, E Function(T state)? storeInitializer}) {
    E? store = _stateScope.getStoreOfExactType<T, E>();
    if (store == null && initializer != null) {
      store = storeInitializer?.call(initializer()) ?? MvcRawStore<T>(initializer()) as E;
      _stateScope.addStore<T, E>(store);
    }
    assert(store != null, "can't find state $T in context");
    return useStateOfExactRawStore<T, R, E>(store!, fn);
  }

  /// Subscribes to a specific store instance.
  R useStateOfExactRawStore<T extends Object, R, E extends MvcRawStore<T>>(E store, R Function(T use) fn) {
    assert(_context != null, "please call setUpBeforUse(context) before useState");
    assert(_context!.debugDoingBuild, 'can only be called during build');
    return store.useState<R>(_context!, fn);
  }
}

/// Extension methods for [BuildContext] to interact with the MVC framework.
extension MvcServicesExtension on BuildContext {
  /// Gets a service of type [T] from the nearest [ServiceProvider].
  /// Throws an error if the service is not found.
  T getService<T extends Object>() {
    assert(MvcApp._debugHasMvcApp(this));
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).getService<T>();
    }
    return _InheritedServiceProvider.of(this)!.get<T>();
  }

  /// Tries to get a service of type [T] from the nearest [ServiceProvider].
  /// Returns `null` if the service is not found.
  T? tryGetService<T extends Object>() {
    assert(MvcApp._debugHasMvcApp(this));
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).tryGetService<T>();
    }
    return _InheritedServiceProvider.of(this)?.tryGet<T>();
  }

  /// Declares a dependency on a [MvcDependableObject].
  ///
  /// When the object changes, the widget will rebuild.
  /// The optional [aspect] can provide more specific information about the dependency.
  void dependOnObject(MvcDependableObject service, {Object? aspect}) {
    assert(MvcApp._debugHasMvcApp(this));
    dependOnInheritedWidgetOfExactType<_MvcApp>(
      aspect: _MvcDependentObjectAspect(
        service,
        aspect: aspect,
      ),
    );
  }

  static final Expando<MvcStateAccessor> _stateAccessor = Expando<MvcStateAccessor>();

  /// Provides access to the state store for reading and subscribing to state changes.
  ///
  /// This must be called within a widget's `build` method.
  ///
  /// ```dart
  /// final count = context.stateAccessor.useState((CounterState state) => state.count);
  /// ```
  MvcStateAccessor get stateAccessor {
    assert(debugDoingBuild, 'can only be called during build');
    assert(MvcApp._debugHasMvcApp(this));
    MvcStateAccessor? accessor = _stateAccessor[this];
    final currentFrame = PlatformDispatcher.instance.frameData.frameNumber;
    if (accessor == null || accessor._frameNumber != currentFrame) {
      accessor = getService<MvcStateAccessor>();
      _stateAccessor[this] = accessor;
      accessor._frameNumber = currentFrame;
      accessor.setUpBeforeUse(this);
    }
    return accessor;
  }

  /// Gets the nearest ancestor [MvcWidgetScope] from this context.
  MvcWidgetScope get widgetScope {
    assert(MvcApp._debugHasMvcApp(this));
    return getService<MvcBasicElement>().widgetScope;
  }

  /// Gets the nearest ancestor [MvcStateScope] from this context.
  MvcStateScope get stateScope {
    assert(MvcApp._debugHasMvcApp(this));
    return getService<MvcBasicElement>().stateScope;
  }
}
