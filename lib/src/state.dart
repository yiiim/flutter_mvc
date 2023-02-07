part of './flutter_mvc.dart';

abstract class MvcState<TControllerType extends MvcController> {
  BuildContext get context;
  TControllerType get controller;

  T? get<T>({String? name});
  MvcStateValue<T>? getValue<T>({String? name});
}

class MvcStateKey {
  MvcStateKey({required this.stateType, this.name});
  final Type stateType;
  final String? name;
  @override
  int get hashCode => Object.hashAll([stateType, name]);

  @override
  bool operator ==(Object other) {
    return other is MvcStateKey && stateType == other.stateType && other.name == name;
  }
}

class MvcStateValue<T> extends ValueNotifier<T> {
  MvcStateValue(super.value, {required this.controller});
  final MvcController controller;

  void update() => notifyListeners();
}
