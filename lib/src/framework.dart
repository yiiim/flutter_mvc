import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';

/// Mvc framework context
///
/// This is the [MvcWidget]'s context, can be get in [MvcStatelessWidget.build] method or [MvcWidgetState.context].
abstract class MvcContext extends BuildContext implements MvcWidgetSelector {
  MvcWidgetScope get scope;
}

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

class MvcApp extends StatelessWidget {
  const MvcApp({
    required this.child,
    this.serviceProvider,
    super.key,
  });
  final Widget child;
  final ServiceProvider? serviceProvider;
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
      child: child,
    );
  }
}

class _MvcApp extends InheritedWidget {
  const _MvcApp({
    this.serviceProvider,
    required super.child,
  });
  final ServiceProvider? serviceProvider;

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

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    WidgetsFlutterBinding.ensureInitialized();
    final Set<_MvcDependentObjectAspect>? dependencies = getDependencies(dependent) as Set<_MvcDependentObjectAspect>?;
    if (aspect == null) {
      setDependencies(dependent, HashSet<_MvcDependentObjectAspect>());
    } else {
      assert(aspect is _MvcDependentObjectAspect);
      _MvcDependentObjectAspect serviceAspect = aspect as _MvcDependentObjectAspect;
      serviceAspect.service.updateDependencies(dependent, aspect: serviceAspect.aspect);
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
        element.removeDependencies(dependent);
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

mixin MvcBasicElement on ComponentElement, DependencyInjectionService implements MvcContext {
  ServiceProvider? scopedServiceProvider;
  late final _MvcWeakReferenceList<MvcWidgetService> _elementServices = _MvcWeakReferenceList();
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
    (state as MvcWidgetState?)?.initServices(collection, parent);
    super.initServices(collection, parent);
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

mixin MvcDependableObject {
  final Map<Element, Object?> _dependents = HashMap<Element, Object?>();

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

class MvcRawStore<T> with MvcDependableObject {
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
      if (element.shouldNotify(state)) {
        return true;
      }
    }
    return false;
  }

  R useState<R>(BuildContext context, [R Function(T state)? use]) {
    assert(context.debugDoingBuild, 'can only be called during build');
    final value = use?.call(state) ?? state as R;
    context.dependOnMvcService(
      this,
      aspect: _MvcStateStoreAspect<T, R>(
        selector: use,
        value: value,
      ),
    );
    return value;
  }

  void setState(void Function(T state) set) {
    set(state);
    notifyAllDependents();
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

class MvcStateAccessor with DependencyInjectionService, MvcDependableObject {
  late final _MvcStoreRepository _storeRepository = getService<_MvcStoreRepository>();
  BuildContext? _context;
  static final List<BuildContext> _debugStateAccessorContext = [];
  static bool _debugPostFrameClearAccessor = true;
  int _frameNumber = 0;

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

  R useState<T, R>(R Function(T use) fn, {T Function()? initializer, MvcRawStore<T> Function(T state)? storeInitializer}) {
    return useStateOfExactRawStoreType<T, R, MvcRawStore<T>>(fn, initializer: initializer, storeInitializer: storeInitializer);
  }

  R useStateOfExactRawStoreType<T, R, E extends MvcRawStore<T>>(R Function(T use) fn, {T Function()? initializer, E Function(T state)? storeInitializer}) {
    E? store = _storeRepository.getStore<T, E>();
    if (store == null && initializer != null) {
      store = storeInitializer?.call(initializer()) ?? MvcRawStore<T>(initializer()) as E;
      _storeRepository.addStore<T, E>(store);
    }
    assert(store != null, "can't find state $T in context");
    return useStateOfExactRawStore<T, R, E>(store!, fn);
  }

  R useStateOfExactRawStore<T, R, E extends MvcRawStore<T>>(E store, R Function(T use) fn) {
    assert(_context != null, "please call setUpBeforUse(context) before useState");
    assert(_context!.debugDoingBuild, 'can only be called during build');
    return store.useState<R>(_context!, fn);
  }
}

mixin MvcWidgetService on DependencyInjectionService {
  MvcBasicElement? _element;

  MvcContext get context {
    assert(_element != null, "context unable");
    return _element!;
  }

  void update(VoidCallback fn) {
    assert(_element != null, "context unable");
    fn();
    _element?.markNeedsBuild();
  }

  @mustCallSuper
  void mvcWidgetActivate() {}

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

class MvcWidgetScope with DependencyInjectionService {
  late final _MvcStoreRepository _repository = getService<_MvcStoreRepository>();

  T createState<T>(T state) {
    return createStateOfExactStoreType<T, MvcRawStore<T>>(state).state;
  }

  R createStateOfExactStoreType<T, R extends MvcRawStore<T>>(
    T state, {
    R Function(T state)? initializer,
  }) {
    final store = initializer?.call(state) ?? MvcRawStore<T>(state);
    _repository.addStore<T, R>(store as R);
    return store;
  }

  void setState<T>(void Function(T state) set) {
    setStateOfExactStoreType<T, MvcRawStore<T>>(set);
  }

  void setStateOfExactStoreType<T, E extends MvcRawStore<T>>(void Function(T state) set) {
    final store = _repository.getStore<T, E>();
    assert(store != null, "can't find state $T in scope");
    store?.setState(set);
  }

  MvcRawStore<T>? getStore<T>() {
    return _repository.getStore<T, MvcRawStore<T>>();
  }

  R? getStoreOfExactType<T, R extends MvcRawStore<T>>() {
    return _repository.getStore<T, R>();
  }
}

extension MvcServicesExtension on BuildContext {
  T getMvcService<T extends Object>() {
    assert(MvcApp._debugHasMvcApp(this));
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).getService<T>();
    }
    return _InheritedServiceProvider.of(this)!.get<T>();
  }

  T? tryGetMvcService<T extends Object>() {
    assert(MvcApp._debugHasMvcApp(this));
    if (this is MvcBasicElement) {
      return (this as MvcBasicElement).tryGetService<T>();
    }
    return _InheritedServiceProvider.of(this)?.tryGet<T>();
  }

  T dependOnMvcServiceOfExactType<T extends MvcDependableObject>({Object? aspect}) {
    assert(MvcApp._debugHasMvcApp(this));
    var service = getMvcService<T>();
    dependOnMvcService(
      service,
      aspect: aspect,
    );
    return service;
  }

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

  void dependOnMvcService(MvcDependableObject service, {Object? aspect}) {
    assert(MvcApp._debugHasMvcApp(this));
    dependOnInheritedWidgetOfExactType<_MvcApp>(aspect: _MvcDependentObjectAspect(service, aspect: aspect));
  }

  static final Expando<MvcStateAccessor> _stateAccessor = Expando<MvcStateAccessor>();
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
    Timer.run(() => accessor); // keep accessor alive until this frame end
    return accessor;
  }
}
