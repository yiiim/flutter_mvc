part of './flutter_mvc.dart';

abstract class MvcWidget<TControllerType extends MvcController> extends Widget {
  const MvcWidget({super.key});

  @override
  MvcWidgetElement<TControllerType> createElement();
}

abstract class MvcStatelessWidget<TControllerType extends MvcController> extends MvcWidget {
  const MvcStatelessWidget({super.key});
  @override
  MvcWidgetElement<TControllerType> createElement() => MvcStatelessElement<TControllerType>(this);
  Widget build(MvcContext context);
}

class MvcBuilder<TControllerType extends MvcController> extends MvcStatelessWidget<TControllerType> {
  const MvcBuilder(this.builder, {super.key});
  final Widget Function(MvcContext context) builder;

  @override
  Widget build(MvcContext context) => builder(context);
}

abstract class MvcStatefulWidget<TControllerType extends MvcController> extends MvcWidget {
  const MvcStatefulWidget({super.key});

  @override
  MvcWidgetElement createElement() => MvcStatefulElement<TControllerType>(this);
  MvcWidgetState createState();
}

abstract class MvcWidgetState<TControllerType extends MvcController, T extends MvcStatefulWidget<TControllerType>> with DependencyInjectionService {
  MvcStatefulElement<TControllerType>? _element;
  TControllerType get controller => _element!._controller!;

  T get widget => _widget!;
  T? _widget;

  bool get mounted => _element != null;
  @protected
  @mustCallSuper
  void initService(ServiceCollection collection) {}
  @protected
  @mustCallSuper
  void initState() {}
  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) {}
  @protected
  @mustCallSuper
  void reassemble() {}
  @protected
  @mustCallSuper
  void deactivate() {}
  @protected
  @mustCallSuper
  void activate() {}
  void update() {
    assert(_element != null, "please check mounted is true");
    _element!.markNeedsBuild();
  }

  Widget build(BuildContext context);
}
