part of './flutter_mvc.dart';

mixin MvcWidgetElement<TControllerType extends MvcController> on Element {
  TControllerType? _controller;
  bool _isFirstBuild = false;
  void _myFirstBuild() {
    _controller = Mvc.get(context: this);
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

class MvcStatefulElement<TControllerType extends MvcController> extends StatefulElement with MvcWidgetElement<TControllerType> {
  MvcStatefulElement(MvcStatefulWidget widget) : super(widget) {
    if (state is MvcWidgetState) {
      (state as MvcWidgetState)._element = this;
    }
  }

  @override
  void _myFirstBuild() {
    super._myFirstBuild();
    if (state is MvcWidgetState) {
      var mvcWidgetState = state as MvcWidgetState;
      if (_controller != null) {
        _controller!.buildScopedServiceProvider(builder: (collection) => collection.add<MvcWidgetState>((serviceProvider) => mvcWidgetState, initializeWhenServiceProviderBuilt: true));
      }
      mvcWidgetState.initMvcWidgetState();
    }
  }
}
