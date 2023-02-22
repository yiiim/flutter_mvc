part of './flutter_mvc.dart';

abstract class MvcState<TControllerType extends MvcController> {
  BuildContext get context;
  TControllerType get controller;

  T? get<T>({Object? key});
  MvcStateValue<T>? getValue<T>({Object? key});
}

class MvcStateKey {
  MvcStateKey({required this.stateType, this.key});
  final Type stateType;
  final Object? key;

  @override
  int get hashCode => Object.hashAll([stateType, key]);

  @override
  bool operator ==(Object other) {
    return other is MvcStateKey && stateType == other.stateType && other.key == key;
  }
}

class MvcStateValue<T> extends ValueNotifier<T> {
  MvcStateValue(super.value, {required this.controller});
  final MvcController controller;
  void update() => notifyListeners();
}

class MvcDependentStateValue<T> extends MvcStateValue<T> {
  MvcDependentStateValue(super.value, Set<MvcStateValue> dependentStates, {required super.controller}) {
    _dependentStates = dependentStates..forEach(_dependentStatesAddListener);
  }
  Set<MvcStateValue> _dependentStates = {};
  FutureOr _dependentStateListener() {
    notifyListeners();
  }

  void _dependentStatesRemoveListener(MvcStateValue stateValue) => stateValue.removeListener(_dependentStateListener);
  void _dependentStatesAddListener(MvcStateValue stateValue) => stateValue.addListener(_dependentStateListener);

  void updateDependentStates(Set<MvcStateValue> dependentStates) {
    Set<MvcStateValue> addListenerDependentStates = {...dependentStates};
    for (var element in _dependentStates) {
      if (addListenerDependentStates.contains(element)) {
        addListenerDependentStates.remove(element);
      } else {
        _dependentStatesRemoveListener(element);
      }
    }
    addListenerDependentStates.forEach(_dependentStatesAddListener);
    _dependentStates = dependentStates;
  }

  @override
  void dispose() {
    _dependentStates.forEach(_dependentStatesRemoveListener);
    super.dispose();
  }
}

abstract class MvcDependentStateValueBuilderContext {
  T? get<T>({Object? key});
  MvcStateValue<T>? getValue<T>({Object? key});
}

class MvcDependentStateValueBuilder<T> extends MvcDependentStateValue<T> {
  MvcDependentStateValueBuilder(super.value, super.dependentStates, {required super.controller, required this.builder});
  final FutureOr<T> Function() builder;
  @override
  FutureOr _dependentStateListener() async {
    var builderValue = builder();
    var newValue = builderValue is T ? builderValue : (await builderValue);
    if (newValue == value) {
      super._dependentStateListener();
    }
    value = newValue;
  }
}

class MvcStateValueTransformer<T, E> extends MvcDependentStateValue<T> {
  MvcStateValueTransformer(T value, this._source, this._transformer, {required super.controller}) : super(value, {_source});
  @override
  FutureOr _dependentStateListener() async {
    var transformValue = _transformer(_source.value);
    var newValue = transformValue is T ? transformValue : (await transformValue);
    if (newValue == value) {
      super._dependentStateListener();
    }
    value = newValue;
  }

  final MvcStateValue<E> _source;
  final FutureOr<T> Function(E state) _transformer;
}
