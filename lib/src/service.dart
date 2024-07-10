import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

abstract class MvcServiceProviderSetUpWidget {
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

class _MvcServiceObserver implements ServiceObserver {
  _MvcServiceObserver(this.element);
  final MvcBasicElement element;
  @override
  void onServiceCreated(service) {
    if (service is MvcWidgetService && service.serviceProvider == element.serviceProvider) {
      element._elementServices.add(service);
    }
  }

  @override
  void onServiceDispose(service) {}

  @override
  void onServiceInitializeDone(service) {}
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

mixin MvcBasicElement on ComponentElement, DependencyInjectionService {
  ServiceProvider? _parentServiceProvider;
  ServiceProvider? scopedServiceProvider;
  late final _MvcWeakReferenceList<MvcWidgetService> _elementServices = _MvcWeakReferenceList();

  @override
  void mount(Element? parent, Object? newSlot) {
    ServiceProvider? parentServiceProvider;
    if (widget is MvcServiceProviderSetUpWidget) {
      parentServiceProvider = (widget as MvcServiceProviderSetUpWidget).serviceProvider;
    } else if (parent != null) {
      parentServiceProvider = _InheritedServiceProvider.of(parent);
    }
    _setUp(parentServiceProvider);
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
  void activate() {
    super.activate();
    ServiceProvider? parentServiceProvider;
    if (widget is MvcServiceProviderSetUpWidget) {
      parentServiceProvider = (widget as MvcServiceProviderSetUpWidget).serviceProvider;
    } else {
      parentServiceProvider = _InheritedServiceProvider.of(this);
    }
    _setUp(parentServiceProvider);
    for (var element in _elementServices.values) {
      element.activate();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    for (var element in _elementServices.values) {
      element.deactivate();
    }
  }

  @override
  Widget build() {
    return _InheritedServiceProvider(
      serviceProvider: serviceProvider,
      child: super.build(),
    );
  }

  void _setUp(ServiceProvider? parentServiceProvider) {
    if (isAttached && _parentServiceProvider == parentServiceProvider) {
      return;
    }
    _parentServiceProvider = parentServiceProvider;
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
  }

  @mustCallSuper
  @protected
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    collection.addSingleton<MvcBasicElement>((serviceProvider) => this, initializeWhenServiceProviderBuilt: true);
    collection.addSingleton<ServiceObserver>((serviceProvider) => _MvcServiceObserver(this));
  }
}

mixin MvcWidgetService on DependencyInjectionService {
  MvcBasicElement? _element;

  BuildContext get context {
    assert(_element != null, "context unable");
    return _element!;
  }

  void setState(VoidCallback fn) {
    fn();
    _element?.markNeedsBuild();
  }

  @mustCallSuper
  void activate() {
    _element = tryGetService<MvcBasicElement>();
  }

  @mustCallSuper
  void deactivate() {
    _element = null;
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    _element = tryGetService<MvcBasicElement>();
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
}
