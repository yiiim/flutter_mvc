part of './flutter_mvc.dart';

mixin MvcWidget<TControllerType extends MvcController> on Widget {
  String? get id;
  List<String>? get classes;
}

abstract class MvcStatelessWidget<TControllerType extends MvcController> extends StatelessWidget with MvcWidget {
  const MvcStatelessWidget({this.id, this.classes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;

  @override
  StatelessElement createElement() => MvcStatelessElement<TControllerType>(this);
}

abstract class MvcStatefulWidget<TControllerType extends MvcController> extends StatefulWidget with MvcWidget {
  const MvcStatefulWidget({this.id, this.classes, super.key});

  @override
  final String? id;
  @override
  final List<String>? classes;

  @override
  StatefulElement createElement() => MvcStatefulElement<TControllerType>(this);

  @override
  MvcWidgetState<TControllerType, MvcStatefulWidget<TControllerType>> createState();
}

abstract class MvcWidgetState<TControllerType extends MvcController, T extends MvcStatefulWidget<TControllerType>> extends State<T> with DependencyInjectionService {
  TControllerType get controller => (context as MvcStatefulElement<TControllerType>)._controller!;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    controller.buildScopedServiceProvider(
      builder: (collection) {
        collection.addSingleton<MvcWidgetState>((serviceProvider) => this, initializeWhenServiceProviderBuilt: true);
        collection.addSingleton<MvcWidgetState<TControllerType, T>>((serviceProvider) => this);
        collection.addSingleton((serviceProvider) => MvcWidgetManager());
      },
    );
  }
}
