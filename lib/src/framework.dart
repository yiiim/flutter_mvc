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
    final InheritedServiceProvider? inheritedServiceProvider = context.getInheritedWidgetOfExactType<InheritedServiceProvider>();
    return inheritedServiceProvider?.serviceProvider;
  }
}

mixin MvcWidgetElement<TControllerType extends MvcController> on ComponentElement implements MvcContext<TControllerType> {
  late final MvcWidgetManager manager = MvcWidgetManager(this, blocker: blockParentFind);
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
    manager.activate(newParent: newParentManager);
  }

  @override
  void deactivate() {
    super.deactivate();
    manager.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    manager.unmount();
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
