import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';

/// The context for an [MvcWidget].
///
/// This is the context of an [MvcWidget], which can be obtained in the
/// [MvcStatelessWidget.build] method or via [MvcWidgetState.context].
/// It provides access to the widget's scope and selector queries.
abstract class MvcContext extends BuildContext implements MvcWidgetSelector {
  /// The scope of the [MvcWidget], providing access to state management.
  MvcWidgetScope get scope;
}

/// A base class for widgets in the MVC framework.
///
/// Do not use this class directly. Instead, use [MvcStatelessWidget] or [MvcStatefulWidget].
///
/// Widgets extending [MvcStatelessWidget] or [MvcStatefulWidget] can be updated
/// via [MvcController.querySelectorAll].
///
/// Example of updating by type:
/// ```dart
/// class MyWidget extends MvcStatelessWidget {
///   const MyWidget({required this.title, super.key, super.id, super.classes});
///   final String title;
///   @override
///   Widget build(BuildContext context) {
///     return Text(title);
///   }
/// }
///
/// // In the controller:
/// class MyController extends MvcController {
///   void updateMyWidget() {
///     // This will find all MyWidget instances and trigger their rebuild.
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
///     return MyWidget(title: controller.title, id: "my-widget", classes: ["my-class"]);
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
/// The `build` method's context can be cast to [MvcContext].
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
  final void Function(ServiceCollection? collection)? serviceProviderBuilder;
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
  final void Function(ServiceCollection? collection)? serviceProviderBuilder;
  @override
  InheritedElement createElement() => _MvcAppElement(this);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _MvcDependentObjectAspect {
  _MvcDependentObjectAspect(this.service, {this.aspect, this.group});
  final MvcDependableObject service;
  final Object? aspect;
  final Object? group;

  @override
  bool operator ==(Object other) => other is _MvcDependentObjectAspect && other.service == service && other.aspect == aspect;

  @override
  int get hashCode => service.hashCode ^ (aspect?.hashCode ?? 0);
}

class _MvcAppElement extends InheritedElement {
  _MvcAppElement(_MvcApp widget) : super(widget);

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final Set<_MvcDependentObjectAspect>? dependencies = getDependencies(dependent) as Set<_MvcDependentObjectAspect>?;
    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcDependentObjectAspect>());
    } else {
      assert(aspect is _MvcDependentObjectAspect);
      _MvcDependentObjectAspect serviceAspect = aspect as _MvcDependentObjectAspect;
      serviceAspect.service.updateDependencies(_MvcDependableElementListener(dependent), aspect: serviceAspect.aspect, group: serviceAspect.group);
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
      serviceProvider: (widget as _MvcApp).serviceProvider ?? ServiceCollection().build(),
      child: MvcDependencyProvider(
        child: MvcStateScope(builder: (_) => super.build()),
        provider: (collection) {
          (widget as _MvcApp).serviceProviderBuilder?.call(collection);
          collection.add<MvcStateAccessor>((_) => MvcStateAccessor());
          collection.addScopedSingleton(
            (_) => MvcWidgetScope(),
            initializeWhenServiceProviderBuilt: true,
          );
          collection.addSingleton<_MvcStoreRepository>(
            (_) => _MvcStoreRepository._internal(null),
            initializeWhenServiceProviderBuilt: true,
          );
        },
      ),
    );
  }

  void clearObjectDependencies(Element dependent) {
    setDependencies(dependent, null);
  }
}

class _MvcWeakReferenceList<T extends Object> {
  final Expando<T> _expando = Expando<T>();
  final List<Finalizer> _list = [];

  void add(T value) {
    Finalizer? finalizer;
    finalizer = Finalizer(
      (_) {
        _list.remove(finalizer);
      },
    );
    finalizer.attach(value, this, detach: value);
    _expando[finalizer] = value;
    _list.add(finalizer);
  }

  void remove(T value) {
    for (var element in _list) {
      final T? v = _expando[element];
      if (v == value) {
        element.detach(value);
        _list.remove(element);
        break;
      }
    }
  }

  void dispose() {
    for (var element in _list) {
      final T? value = _expando[element];
      if (value != null) {
        element.detach(value);
      }
    }
    _list.clear();
  }

  Iterable<T> get values => _list.map((container) => _expando[container]).whereType<T>();
}

/// A mixin for `Element`s that provides basic MVC framework functionalities,
/// including dependency injection scope management.
mixin MvcBasicElement on ComponentElement, DependencyInjectionService implements MvcContext {
  ServiceProvider? scopedServiceProvider;
  late final _MvcWeakReferenceList<MvcWidgetService> _elementServices = _MvcWeakReferenceList();

  /// Determines whether this element creates a new state scope.
  bool get createStateScope => false;
  @override
  late final MvcWidgetScope scope = getMvcService<MvcWidgetScope>();
  @override
  void mount(Element? parent, Object? newSlot) {
    assert(MvcApp._debugHasMvcApp(parent));
    ServiceProvider? parentServiceProvider;
    if (parent != null) {
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
  void dispose() {
    super.dispose();
    scopedServiceProvider?.dispose();
    _elementServices.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    for (var element in _elementServices.values) {
      element.mvcWidgetDeactivate();
    }
  }

  @override
  void activate() {
    super.activate();
    ServiceProvider? parentServiceProvider;
    parentServiceProvider = _InheritedServiceProvider.of(this);
    scopedServiceProvider!.transferScope(parentServiceProvider);
    for (var element in _elementServices.values) {
      element.mvcWidgetActivate();
    }
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
    collection.addSingleton<MvcContext>(
      (serviceProvider) => this,
      initializeWhenServiceProviderBuilt: true,
    );
    if (createStateScope) {
      collection.addSingleton<_MvcStoreRepository>(
        (serviceProvider) => _MvcStoreRepository._internal(
          parent?.tryGet<_MvcStoreRepository>(),
        ),
        initializeWhenServiceProviderBuilt: true,
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
  @override
  MvcContext get context => super.context as MvcContext;

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
  Iterable<MvcWidgetUpdater> querySelectorAll<E>([String? selectors, bool ignoreSelectorBreaker = false]) => context.querySelectorAll<E>(selectors, ignoreSelectorBreaker);
  @override
  MvcWidgetUpdater? querySelector<E>([String? selectors, bool ignoreSelectorBreaker = false]) => context.querySelector<E>(selectors, ignoreSelectorBreaker);
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

class _MvcDependableStateListener<T, R> extends MvcDependableListener {
  _MvcDependableStateListener({
    required this.state,
    required this.listener,
    this.selector,
  });
  final T state;
  final void Function(R value) listener;
  final R Function(T state)? selector;
  @override
  void onDependencyChanged(Object? aspect) {
    final value = selector?.call(state) ?? state as R;
    listener(value);
  }

  @override
  bool operator ==(Object other) => other is _MvcDependableStateListener && other.state == state && other.listener == listener;

  @override
  int get hashCode => state.hashCode ^ listener.hashCode;
}

/// A mixin for objects that can be depended upon by widgets.
///
/// When the object changes, it can notify its dependents to rebuild.
/// This is the foundation for reactive state management in the framework.
mixin MvcDependableObject {
  final Map<MvcDependableListener, Object?> _dependents = HashMap<MvcDependableListener, Object?>();
  final Map<Object, Set<MvcDependableListener>> _dependentGroups = HashMap<Object, Set<MvcDependableListener>>();
  final Map<MvcDependableListener, Object?> _dependentToGroup = HashMap<MvcDependableListener, Object?>();

  /// Gets the dependency aspect for a given listener.
  @protected
  Object? getDependencies(MvcDependableListener dependent) {
    return _dependents[dependent];
  }

  /// Sets the dependency aspect for a given listener, optionally within a group.
  @protected
  void setDependencies(MvcDependableListener dependent, Object? value, {Object? group}) {
    _dependents[dependent] = value;

    // Remove dependent from previous group if it exists
    final previousGroup = _dependentToGroup[dependent];
    if (previousGroup != null && previousGroup != group) {
      final previousGroupSet = _dependentGroups[previousGroup];
      if (previousGroupSet != null) {
        previousGroupSet.remove(dependent);
        // Clean up empty group
        if (previousGroupSet.isEmpty) {
          _dependentGroups.remove(previousGroup);
        }
      }
    }

    // Add dependent to new group if group is specified
    if (group != null) {
      _dependentGroups.putIfAbsent(group, () => HashSet<MvcDependableListener>()).add(dependent);
      _dependentToGroup[dependent] = group;
    } else {
      // If no group specified, remove from group tracking
      _dependentToGroup.remove(dependent);
    }
  }

  /// Updates the dependencies for a listener.
  @protected
  void updateDependencies(MvcDependableListener dependent, {Object? aspect, Object? group}) {
    setDependencies(dependent, aspect, group: group);
  }

  /// Removes a dependent listener.
  @protected
  void removeDependencies(MvcDependableListener element) {
    _dependents.remove(element);

    // Remove from group tracking
    final group = _dependentToGroup.remove(element);

    // Remove from the specific group if it exists
    if (group != null) {
      final groupSet = _dependentGroups[group];
      if (groupSet != null) {
        groupSet.remove(element);
        // Clean up empty group
        if (groupSet.isEmpty) {
          _dependentGroups.remove(group);
        }
      }
    } else {
      // Fallback: remove from all groups (in case of inconsistent state)
      for (var groupSet in _dependentGroups.values) {
        groupSet.remove(element);
      }
      _dependentGroups.removeWhere((key, value) => value.isEmpty);
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

  /// Notifies all dependents within a specific group of a change.
  @protected
  void notifyDependentsInGroup(Object group) {
    final dependentsInGroup = _dependentGroups[group];
    if (dependentsInGroup != null) {
      for (final dependent in dependentsInGroup) {
        final aspect = _dependents[dependent];
        if (shouldNotifyDependents(dependent, aspect: aspect)) {
          notifyDependent(dependent, aspect: aspect);
        }
      }
    }
  }

  /// Gets all available dependency groups.
  Set<Object> get dependencyGroups => _dependentGroups.keys.toSet();

  /// Checks if a dependency group exists.
  bool hasDependencyGroup(Object group) => _dependentGroups.containsKey(group);

  /// Gets the count of dependents in a specific group.
  int getDependentsCountInGroup(Object group) => _dependentGroups[group]?.length ?? 0;

  /// Removes all dependents from a specific group.
  void clearDependencyGroup(Object group) {
    final dependentsInGroup = _dependentGroups[group];
    if (dependentsInGroup != null) {
      // Remove these dependents from the main _dependents map
      for (final dependent in dependentsInGroup) {
        _dependents.remove(dependent);
      }
      // Remove the group
      _dependentGroups.remove(group);
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
class MvcRawStore<T> with MvcDependableObject {
  /// The state object.
  final T state;

  /// Creates a raw store with the initial state.
  MvcRawStore(this.state);

  @override
  void updateDependencies(MvcDependableListener dependent, {Object? aspect, Object? group}) {
    final Set<_MvcStateStoreAspect>? dependencies = getDependencies(dependent) as Set<_MvcStateStoreAspect>?;
    if (dependencies != null && dependencies.isEmpty) {
      return;
    }

    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcStateStoreAspect>(), group: group);
    } else {
      assert(aspect is _MvcStateStoreAspect);
      setDependencies(
        dependent,
        (dependencies ?? HashSet<_MvcStateStoreAspect>())..add(aspect as _MvcStateStoreAspect),
        group: group,
      );
    }
  }

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
    final value = use?.call(state) ?? state as R;
    context.dependOnMvcService(
      this,
      aspect: _MvcStateStoreAspect<T, R>(
        selector: use,
        value: value,
      ),
      group: T,
    );
    return value;
  }

  /// Updates the state and notifies listening widgets.
  ///
  /// The [set] function receives the current state and can modify it.
  void setState(void Function(T state) set) {
    set(state);
    notifyDependentsInGroup(T);
  }
}

class _MvcStoreRepository with DependencyInjectionService {
  _MvcStoreRepository._internal(this._parent);
  final _MvcStoreRepository? _parent;
  final Map<Type, MvcRawStore> _stores = {};
  late final Widget debugWidget;
  R? getStore<T, R extends MvcRawStore<T>>() {
    return _stores[T] as R? ?? _parent?.getStore<T, R>();
  }

  void addStore<T, R extends MvcRawStore<T>>(R store) {
    assert(!_stores.containsKey(T), "state $T already exists");
    _stores[T] = store;
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    assert(() {
      final element = tryGetService<MvcBasicElement>();
      assert(element != null, "can't find MvcBasicElement");
      debugWidget = element!.widget;
      return true;
    }());
  }
}

/// A widget that creates a new state scope.
///
/// States created within this scope will not conflict with states of the same
/// type in parent scopes.
class MvcStateScope extends MvcStatefulWidget {
  /// Creates a state scope widget.
  const MvcStateScope({required this.builder, super.key});

  /// A builder for the child widget.
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

/// Provides access to the state store for reading and subscribing to state changes.
///
/// This should be used within a widget's `build` method via `context.stateAccessor`.
class MvcStateAccessor with DependencyInjectionService {
  late final _MvcStoreRepository _storeRepository = getService<_MvcStoreRepository>();
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
  R useState<T, R>(R Function(T use) fn, {T Function()? initializer, MvcRawStore<T> Function(T state)? storeInitializer}) {
    return useStateOfExactRawStoreType<T, R, MvcRawStore<T>>(fn, initializer: initializer, storeInitializer: storeInitializer);
  }

  /// A more specific version of [useState] that allows specifying the exact store type.
  R useStateOfExactRawStoreType<T, R, E extends MvcRawStore<T>>(R Function(T use) fn, {T Function()? initializer, E Function(T state)? storeInitializer}) {
    E? store = _storeRepository.getStore<T, E>();
    if (store == null && initializer != null) {
      store = storeInitializer?.call(initializer()) ?? MvcRawStore<T>(initializer()) as E;
      _storeRepository.addStore<T, E>(store);
    }
    assert(store != null, "can't find state $T in context");
    return useStateOfExactRawStore<T, R, E>(store!, fn);
  }

  /// Subscribes to a specific store instance.
  R useStateOfExactRawStore<T, R, E extends MvcRawStore<T>>(E store, R Function(T use) fn) {
    assert(_context != null, "please call setUpBeforUse(context) before useState");
    assert(_context!.debugDoingBuild, 'can only be called during build');
    return store.useState<R>(_context!, fn);
  }
}

/// A mixin for services that need to be associated with an [MvcWidget].
///
/// This provides access to the widget's [context] and a way to trigger updates.
/// It also provides lifecycle methods that are tied to the widget's lifecycle.
mixin MvcWidgetService on DependencyInjectionService {
  MvcBasicElement? _element;

  /// The context of the associated widget.
  MvcContext get context {
    assert(_element != null, "context unable");
    return _element!;
  }

  /// Triggers a rebuild of the associated widget.
  void update(VoidCallback fn) {
    assert(_element != null, "context unable");
    fn();
    _element?.markNeedsBuild();
  }

  /// Called when the associated widget is activated.
  @mustCallSuper
  void mvcWidgetActivate() {}

  /// Called when the associated widget is deactivated.
  @mustCallSuper
  void mvcWidgetDeactivate() {}

  @mustCallSuper
  @override
  void dispose() {
    _element?._elementServices.remove(this);
    _element = null;
    super.dispose();
  }

  @mustCallSuper
  @override
  FutureOr dependencyInjectionServiceInitialize() {
    _element = tryGetService<MvcBasicElement>();
    _element?._elementServices.add(this);
  }
}

/// Provides a scope for creating and managing states.
///
/// This is typically obtained via dependency injection and used to interact
/// with the state store outside of the widget build process (e.g., in a controller or service).
class MvcWidgetScope with DependencyInjectionService {
  late final _MvcStoreRepository _repository = getService<_MvcStoreRepository>();

  /// Creates and registers a new state of type [T].
  /// Throws an error if a state of the same type already exists in the current scope.
  T createState<T>(T state) {
    return createStateOfExactStoreType<T, MvcRawStore<T>>(state).state;
  }

  /// A more specific version of [createState] that allows specifying the exact store type.
  R createStateOfExactStoreType<T, R extends MvcRawStore<T>>(
    T state, {
    R Function(T state)? initializer,
  }) {
    final store = initializer?.call(state) ?? MvcRawStore<T>(state);
    _repository.addStore<T, R>(store as R);
    return store;
  }

  /// Updates a state of type [T].
  /// The [set] function receives the current state and can modify it.
  void setState<T>(void Function(T state) set) {
    setStateOfExactStoreType<T, MvcRawStore<T>>(set);
  }

  /// A more specific version of [setState] that allows specifying the exact store type.
  void setStateOfExactStoreType<T, E extends MvcRawStore<T>>(void Function(T state) set) {
    final store = _repository.getStore<T, E>();
    assert(store != null, "can't find state $T in scope");
    setStateOfExactStore<T, E>(store!, set);
  }

  /// Updates a specific store instance.
  void setStateOfExactStore<T, R extends MvcRawStore<T>>(R store, void Function(T state) set) {
    store.setState(set);
  }

  /// Gets the raw store for a state of type [T].
  MvcRawStore<T>? getStore<T>() {
    return _repository.getStore<T, MvcRawStore<T>>();
  }

  /// A more specific version of [getStore] that allows specifying the exact store type.
  R? getStoreOfExactType<T, R extends MvcRawStore<T>>() {
    return _repository.getStore<T, R>();
  }

  /// Listens to changes in a state of type [T] and returns a value of type [R].
  ///
  /// The [listener] is called whenever the selected part of the state changes.
  /// The [use] function selects the part of the state to listen to.
  R listenState<T, R>(void Function(R value) listener, [R Function(T state)? use]) {
    final store = getStore<T>();
    assert(store != null, "can't find state $T in scope");
    final value = use?.call(store!.state) ?? store!.state as R;
    store!.updateDependencies(
      _MvcDependableStateListener(
        state: store.state,
        listener: listener,
        selector: use,
      ),
      aspect: _MvcStateStoreAspect<T, R>(
        selector: use,
        value: value,
      ),
      group: T,
    );
    return value;
  }

  /// Removes a state listener.
  void removeStateListener<T>(void Function(Object? state) listener) {
    final store = getStore<T>();
    assert(store != null, "can't find state $T in scope");
    store?.removeDependencies(
      _MvcDependableStateListener(
        state: store.state,
        listener: listener,
      ),
    );
  }
}

/// Extension methods for [BuildContext] to interact with the MVC framework.
extension MvcServicesExtension on BuildContext {
  /// Gets a service of type [T] from the nearest [ServiceProvider].
  /// Throws an error if the service is not found.
  T getMvcService<T extends Object>() {
    assert(MvcApp._debugHasMvcApp(this));
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).getService<T>();
    }
    return _InheritedServiceProvider.of(this)!.get<T>();
  }

  /// Tries to get a service of type [T] from the nearest [ServiceProvider].
  /// Returns `null` if the service is not found.
  T? tryGetMvcService<T extends Object>() {
    assert(MvcApp._debugHasMvcApp(this));
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).tryGetService<T>();
    }
    return _InheritedServiceProvider.of(this)?.tryGet<T>();
  }

  /// Subscribes the widget to a [MvcDependableObject] of type [T].
  ///
  /// When the service changes, the widget will rebuild.
  /// The [aspect] can be used to listen to specific parts of the service.
  T dependOnMvcServiceOfExactType<T extends MvcDependableObject>({Object? aspect}) {
    assert(MvcApp._debugHasMvcApp(this));
    var service = getMvcService<T>();
    dependOnMvcService(
      service,
      aspect: aspect,
    );
    return service;
  }

  /// Tries to subscribe the widget to a [MvcDependableObject] of type [T].
  /// Returns `null` if the service is not found.
  T? tryDependOnMvcServiceOfExactType<T extends MvcDependableObject>({Object? aspect}) {
    assert(MvcApp._debugHasMvcApp(this));
    var service = tryGetMvcService<T>();
    if (service != null) {
      dependOnMvcService(
        service,
        aspect: aspect,
      );
    }
    return service;
  }

  /// Establishes a dependency on a [MvcDependableObject].
  ///
  /// This is a lower-level method for creating a dependency. Prefer using
  /// [dependOnMvcServiceOfExactType] when possible.
  void dependOnMvcService(MvcDependableObject service, {Object? aspect, Object? group}) {
    assert(MvcApp._debugHasMvcApp(this));
    dependOnInheritedWidgetOfExactType<_MvcApp>(
      aspect: _MvcDependentObjectAspect(
        service,
        aspect: aspect,
        group: group,
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
      accessor = getMvcService<MvcStateAccessor>();
      _stateAccessor[this] = accessor;
      accessor._frameNumber = currentFrame;
      accessor.setUpBeforeUse(this);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // keep accessor alive until this frame end
      accessor;
    });
    return accessor;
  }
}
