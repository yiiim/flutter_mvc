import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_mvc/src/selector/node.dart';

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

/// Mvc framework context
///
/// This is the [MvcWidget]'s context, can be get in [MvcStatelessWidget.build] method or [MvcWidgetState.context].
abstract class MvcContext extends BuildContext implements MvcWidgetSelector {
  /// Depend on a service, if the service is not exist, will throw an exception.
  ///
  /// If the service is [MvcService],this context will be update when the service call [MvcService.update].
  ///
  /// Alse will be update when the nearest [Mvc] call [MvcController.updateService<T>].
  ///
  /// See [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection) about how to inject service.
  T dependOnService<T extends Object>();

  /// Try depend on a service, if the service is not exist, will return null.
  /// Same as [dependOnService] but not throw an exception when the service is not exist.
  T? tryDependOnService<T extends Object>();

  /// get service in current scope
  T getService<T extends Object>();

  /// get service in current scope
  T? tryGetService<T extends Object>();
}

/// The common element of the [MvcWidget]
mixin MvcWidgetElement<TControllerType extends MvcController> on DependencyInjectionService, MvcBasicElement, MvcNodeMixin implements MvcContext {
  late final Map<Type, Object> _dependencieServices = {};

  @override
  MvcWidget get widget => super.widget as MvcWidget;

  TControllerType? _controller;

  /// the nearest [Mvc]'s controller in this context if of type [TControllerType]
  TControllerType get controller {
    assert(_controller != null, '$TControllerType not found in current context');
    return _controller!;
  }

  /// you can be inject some services here when [ServiceProvider] is created
  @mustCallSuper
  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
  }

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
  FutureOr dependencyInjectionServiceInitialize() {
    _controller = tryGetService<TControllerType>();
    return super.dependencyInjectionServiceInitialize();
  }
}

/// mvc framework stateless element
class MvcStatelessElement<TControllerType extends MvcController> extends StatelessElement with DependencyInjectionService, MvcBasicElement, MvcNodeMixin, MvcWidgetElement<TControllerType> {
  MvcStatelessElement(MvcStatelessWidget widget) : super(widget);
}

/// mvc framework stateful element
class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with DependencyInjectionService, MvcBasicElement, MvcNodeMixin, MvcWidgetElement<TControllerType> {
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget);

  @override
  bool get isSelectorBreaker => (state as MvcWidgetState?)?.isSelectorBreaker ?? super.isSelectorBreaker;

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
  /// Whether to allow queries from superiors to continue looking for children
  bool get isSelectorBreaker => false;
  @override
  MvcContext get context => super.context as MvcContext;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
  }

  /// you can be inject some services here when [ServiceProvider] is created
  @mustCallSuper
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    collection.addSingleton<MvcWidgetState>((serviceProvider) => this, initializeWhenServiceProviderBuilt: true);
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

mixin MvcService on DependencyInjectionService implements MvcWidgetSelector {
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

  @override
  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]) sync* {
    for (var element in _dependents) {
      yield* element.querySelectorAll<T>(selectors, ignoreSelectorBreaker);
    }
  }

  @override
  MvcWidgetUpdater? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]) {
    for (var element in _dependents) {
      var result = element.querySelector<T>(selectors, ignoreSelectorBreaker);
      if (result != null) return result;
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
    _dependents.clear();
  }
}
