part of './flutter_mvc.dart';

class MvcControllerEnvironmentState with MvcStateProviderMixin {
  MvcControllerEnvironmentState({MvcControllerEnvironmentState? parent}) {
    _parent = parent;
  }
  MvcControllerEnvironmentState? _parent;

  @override
  MvcStateValue<T>? getStateValue<T>({Object? key}) {
    return super.getStateValue(key: key) ?? _parent?.getStateValue<T>(key: key);
  }
}
