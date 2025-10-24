import 'package:dart_dependency_injection/dart_dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/src/selector/node.dart';

import 'framework.dart';
import 'selector.dart';

/// An abstract base class for a controller in the MVC design pattern.
///
/// Extend this class to create a controller and override the [view] method to return an [MvcView].
/// The controller is responsible for handling business logic and can access the data model
/// via [model] and the UI context via [context].
///
/// ```dart
/// class MyController extends MvcController<MyModel> {
///   @override
///   MvcView view() => MyView();
///
///   void incrementCounter() {
///     model.counter++;
///     update(); // Rebuilds the view
///   }
/// }
/// ```
///
/// [TModelType] is the type of the data model associated with this controller. Use `void` if no model is needed.
abstract class MvcController<TModelType> with DependencyInjectionService implements MvcWidgetSelector {
  _MvcControllerState? _state;

  /// Gets the data model associated with this controller.
  TModelType get model => _state!.widget.model;

  /// Gets the [BuildContext] for this controller.
  BuildContext get context => _state!.context;

  /// Whether to break the propagation of selector queries.
  ///
  /// If `true`, selector queries will not continue to look up past this `Mvc` widget.
  /// Defaults to `true`.
  bool get isSelectorBreaker => true;

  /// Whether to create a new state scope for this `Mvc` widget.
  ///
  /// Defaults to `true`. When a new state scope is created, child widgets can have
  /// independent states that do not conflict with states of the same type in the parent scope.
  /// See `MvcStateScope` for more details.
  bool get createStateScope => true;

  /// Gets the [MvcStateScope] associated with this controller.
  ///
  /// The [MvcStateScope] provides functionality for creating and updating states.
  late final MvcStateScope stateScope = getService<MvcStateScope>();

  late final MvcWidgetScope widgetScope = getService<MvcWidgetScope>();

  /// Builds the view ([MvcView]) associated with this controller.
  ///
  /// Must be overridden to return an [MvcView] instance.
  ///
  /// ```dart
  /// @override
  /// MvcView view() => MyPageView();
  /// ```
  MvcView view();

  /// Called when the controller is initialized.
  ///
  /// This method is called in the `initState` lifecycle and is suitable for one-time initialization tasks.
  @protected
  void init() {}

  /// Called when the `Mvc` widget's model is updated.
  ///
  /// This method is called in the `didUpdateWidget` lifecycle.
  /// You can compare the [oldModel] with the current [model] to react to model changes.
  @protected
  void didUpdateModel(TModelType oldModel) {}

  /// Called when this controller is activated.
  ///
  /// Called after `initState` or when re-entering the widget tree after `deactivate`.
  @mustCallSuper
  @protected
  void activate() {}

  /// Called when this controller is deactivated.
  ///
  /// Called when this controller is temporarily removed from the widget tree.
  @mustCallSuper
  @protected
  void deactivate() {}

  /// Initializes services in the dependency injection scope of this controller.
  ///
  /// You can register services available to this controller and its children via the [collection].
  ///
  /// ```dart
  /// @override
  /// void initServices(ServiceCollection collection) {
  ///   super.initServices(collection);
  ///   collection.addSingleton<MyService>((_) => MyService());
  /// }
  /// ```
  @mustCallSuper
  @protected
  void initServices(ServiceCollection collection) {}

  /// Triggers a view rebuild.
  ///
  /// Calling this method re-executes [MvcView.buildView].
  /// If an optional [fn] function is provided, it will be executed before the rebuild.
  ///
  /// ```dart
  /// void updateCounter() {
  ///   update(() {
  ///     _count++;
  ///   });
  /// }
  /// ```
  void update([void Function()? fn]) => _state!._update(fn);

  @override
  Iterable<MvcWidgetScope> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]) => widgetScope.querySelectorAll<T>(
        selectors,
        ignoreSelectorBreaker,
      );
  @override
  MvcWidgetScope? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]) => widgetScope.querySelector<T>(
        selectors,
        ignoreSelectorBreaker,
      );
}

/// A `StatefulWidget` that implements the MVC design pattern.
///
/// The `Mvc` widget connects the model ([TModelType]), view ([MvcView]), and controller ([TControllerType]).
/// It is responsible for creating and managing the controller's lifecycle and building the view defined by the controller.
///
/// ```dart
/// Mvc(
///   create: () => MyController(),
///   model: MyModel(),
/// )
/// ```
class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends MvcStatefulWidget {
  /// Creates an `Mvc` widget.
  ///
  /// The [create] parameter is a factory function for creating the controller instance.
  /// The [model] is the data model passed to the controller.
  /// [id] and [classes] are used for the selector feature.
  const Mvc({this.create, TModelType? model, Key? key, super.id, super.classes})
      : model = model ?? model as TModelType,
        super(key: key);

  /// A factory function to create an instance of [TControllerType].
  ///
  /// If `null`, the framework will attempt to get a `_MvcControllerProvider` from the parent's
  /// dependency injection container to create the controller.
  /// See [MvcControllerServiceCollection.addController].
  final TControllerType Function()? create;

  /// The data model associated with the controller.
  final TModelType model;

  @override
  MvcWidgetState createState() => _MvcControllerState<TControllerType, TModelType>();

  /// Queries for all `MvcWidget`s that match the selector, starting from the root scope.
  ///
  /// [selectors] is a CSS-like selector string used to match the `id`, `classes`, `attributes`, or type of an `MvcWidget`.
  ///
  /// Examples: `#my-id`, `.my-class`, `[data-value='123']`, `MyWidget`.
  ///
  /// Returns an iterable list of [MvcWidgetScope]s that can be used to update the queried widgets.
  static Iterable<MvcWidgetScope> querySelectorAll<T>([String? selectors]) {
    return MvcImplicitRootNode.instance.querySelectorAll<T>(selectors);
  }

  /// Queries for the first `MvcWidget` that matches the selector, starting from the root scope.
  ///
  /// [selectors] is a CSS-like selector string.
  ///
  /// Returns an [MvcWidgetScope] instance, or `null` if not found.
  static MvcWidgetScope? querySelector<T>([String? selectors]) {
    return MvcImplicitRootNode.instance.querySelector<T>(selectors);
  }
}

class _MvcControllerState<TControllerType extends MvcController<TModelType>, TModelType> extends MvcWidgetState {
  @override
  Mvc<TControllerType, TModelType> get widget => super.widget as Mvc<TControllerType, TModelType>;

  late final TControllerType controller;

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
    TControllerType? controller = widget.create?.call() ?? parent?.get<_MvcControllerProvider<TControllerType>>().create();
    assert(controller != null, "can't create controller");
    this.controller = controller!;
    super.initServices(collection, parent);
    controller._state = this;
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

/// An abstract base class for a view in the MVC design pattern.
///
/// Extend this class to create a view and implement the [buildView] method to build your UI.
/// The view can access its associated controller via the [controller] property to get data and call methods.
///
/// ```dart
/// class MyView extends MvcView<MyController> {
///   @override
///   Widget buildView() {
///     return Scaffold(
///       appBar: AppBar(title: Text(controller.title)),
///       body: Center(
///         child: Text('Counter: ${controller.model.counter}'),
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: () => controller.incrementCounter(),
///         child: Icon(Icons.add),
///       ),
///     );
///   }
/// }
/// ```
///
/// [TControllerType] is the type of the controller associated with this view.
abstract class MvcView<TControllerType extends MvcController> with DependencyInjectionService {
  /// Gets the controller instance associated with this view.
  late final TControllerType controller = getService<TControllerType>();

  /// Gets the [BuildContext] for the current view.
  BuildContext get context => controller.context;

  /// Builds the UI for the view.
  ///
  /// This method is called by the framework to render the view. It should return a Widget.
  Widget buildView();
}

/// A generic [MvcView] implementation that uses a builder function to create the view.
///
/// This is useful for simple scenarios that do not require a separate view class.
///
/// ```dart
/// class MyController extends MvcController {
///   @override
///   MvcView view() {
///     return MvcViewBuilder(
///       (controller) => Text('Hello from ${controller.runtimeType}'),
///     );
///   }
/// }
/// ```
class MvcViewBuilder<TControllerType extends MvcController> extends MvcView<TControllerType> {
  /// Creates an [MvcViewBuilder] instance.
  ///
  /// The [builder] is a function that receives the controller instance and returns a Widget.
  MvcViewBuilder(this.builder);

  /// The function used to build the view.
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

/// Provides extension methods for [ServiceCollection] to facilitate controller registration.
extension MvcControllerServiceCollection on ServiceCollection {
  /// Registers a controller factory in the dependency injection container.
  ///
  /// This allows an `Mvc` widget to find and create a controller instance from the parent
  /// dependency injection container when a `create` function is not directly provided.
  ///
  /// ```dart
  /// MvcDependencyProvider(
  ///   provider: (collection) {
  ///     collection.addController<MyController>((_) => MyController());
  ///   },
  ///   child: Mvc<MyController, void>(
  ///     // No `create` parameter needed here
  ///   ),
  /// );
  /// ```
  void addController<T extends MvcController>(T Function(ServiceProvider provider) create) {
    addSingleton<_MvcControllerProvider<T>>((serviceProvider) => _MvcControllerFactoryProvider<T>(() => create(serviceProvider)));
  }
}
