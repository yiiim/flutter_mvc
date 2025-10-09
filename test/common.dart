import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

class TestMvcWidget extends MvcStatelessWidget {
  const TestMvcWidget({required this.builder, super.key, super.id, super.classes, super.attributes});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

class TestService with DependencyInjectionService, MvcDependableObject {
  TestService();
  String stateValue = "";

  void update(VoidCallback fn) {
    fn();
    notifyAllDependents();
  }

  // Public methods for testing dependency groups
  void addDependency(MvcDependableListener listener, Object? aspect, {Object? group}) {
    setDependencies(listener, aspect, group: group);
  }

  void removeDependency(MvcDependableListener listener) {
    removeDependencies(listener);
  }

  void notifyGroup(Object group) {
    notifyDependentsInGroup(group);
  }
}

class TestModel {
  const TestModel(this.modelValue, {required this.builder});
  final String modelValue;
  final Widget Function(BuildContext context) builder;
}

class TestView extends MvcView<TestController> {
  @override
  Widget buildView() {
    return controller.model.builder(context);
  }
}

class TestController extends MvcController<TestModel> {
  String controllerValue = "";
  bool isDisposed = false;
  @override
  MvcView view() => TestView();

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
