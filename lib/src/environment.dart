part of './flutter_mvc.dart';

class MvcControllerEnvironment with MvcStateProviderMixin implements MvcControllerEnvironmentStateProvider {
  MvcControllerEnvironment({MvcControllerEnvironment? parent}) {
    _parent = parent;
  }
  MvcControllerEnvironment? _parent;

  @override
  MvcStateValue<T>? getStateValue<T>({Object? key}) {
    return super.getStateValue(key: key) ?? _parent?.getStateValue<T>(key: key);
  }
}
