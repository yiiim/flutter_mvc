part of './flutter_mvc.dart';

mixin MvcWidgetElement<TControllerType extends MvcController> on Element {
  TControllerType? _controller;
  bool _isFirstBuild = false;
  void _myFirstBuild() {
    _controller = Mvc.get(context: this);
    _controller?.getService<MvcWidgetManager>()._registerWidget(this);
  }

  @override
  void update(covariant Widget newWidget) {
    var oldWidget = widget;
    super.update(newWidget);
    _controller?.getService<MvcWidgetManager>()._updateWidget(oldWidget, this);
  }

  @override
  void rebuild({bool force = false}) {
    if (_isFirstBuild == false) {
      _isFirstBuild = true;
      _myFirstBuild();
    }
    super.rebuild(force: force);
  }
}

class MvcStatelessElement<TControllerType extends MvcController> extends ComponentElement with MvcWidgetElement<TControllerType> {
  MvcStatelessElement(super.widget);

  @override
  Widget build() => (widget as MvcStatelessWidget).build(_controller!.context);
}

class MvcStatefulElement<TControllerType extends MvcController> extends ComponentElement with MvcWidgetElement<TControllerType> {
  MvcStatefulElement(MvcStatefulWidget<TControllerType> widget) : super(widget);
  late final ServiceProvider _serviceProvider;
  MvcWidgetState? _state;

  @override
  MvcStatefulWidget<TControllerType> get widget => super.widget as MvcStatefulWidget<TControllerType>;

  @override
  Widget build() => _state!.build(this);

  @override
  void _myFirstBuild() {
    super._myFirstBuild();
    _state = widget.createState();
    _state!._widget = widget;
    _serviceProvider = _controller!.buildScopedServiceProvider(
      builder: (collection) {
        _state!.initService(collection);
        collection.addSingleton<MvcWidgetState>((serviceProvider) => _state!);
      },
    );
    assert(_state == _serviceProvider.get<MvcWidgetState>());
    _state!.initState();
  }

  @override
  void reassemble() {
    _state!.reassemble();
    super.reassemble();
  }

  @override
  void update(MvcStatefulWidget newWidget) {
    super.update(newWidget);
    final MvcStatefulWidget oldWidget = _state!._widget!;
    _state!._widget = widget;
    _state!.didUpdateWidget(oldWidget) as dynamic;
    rebuild(force: true);
  }

  @override
  void activate() {
    super.activate();
    _state!.activate();
    markNeedsBuild();
  }

  @override
  void deactivate() {
    _state!.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    _serviceProvider.dispose();
    _state!._element = null;
    _state = null;
  }
}
