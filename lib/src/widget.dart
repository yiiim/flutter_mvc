part of './flutter_mvc.dart';

abstract class MvcStatefulWidget extends StatefulWidget {
  const MvcStatefulWidget({super.key});

  @override
  StatefulElement createElement() => MvcStatefulElement(this);
}

abstract class MvcWidgetState<T extends MvcStatefulWidget> extends State<T> with DependencyInjectionService {
  MvcController? _controller;
  MvcController get controller => _controller!;
}

mixin MvcWidgetElement on Element {
  MvcController? _controller;
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

class MvcStatefulElement extends StatefulElement with MvcWidgetElement {
  MvcStatefulElement(super.widget);

  @override
  void _myFirstBuild() {
    super._myFirstBuild();
    if (state is MvcWidgetState) {
      var mvcWidgetState = state as MvcWidgetState;
      if (_controller != null) {
        mvcWidgetState._controller = _controller;
        _controller!.buildScopedServiceProvider(builder: (collection) => collection.add<MvcWidgetState>((serviceProvider) => mvcWidgetState, initializeWhenServiceProviderBuilt: true));
      }
    }
  }
}
