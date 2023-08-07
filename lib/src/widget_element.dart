part of './flutter_mvc.dart';

mixin MvcWidgetElement<TControllerType extends MvcController> on Element {
  TControllerType? get _controller => Mvc.get(context: this);
  bool _isFirstBuild = false;
  void _myFirstBuild() {
    // _controller = Mvc.get(context: this);
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

class MvcStatelessElement<TControllerType extends MvcController> extends StatelessElement with MvcWidgetElement<TControllerType> {
  MvcStatelessElement(MvcStatelessWidget widget) : super(widget);
}

class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with MvcWidgetElement<TControllerType> {
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget);
}
