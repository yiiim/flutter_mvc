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

class MvcStateValue<T> extends ChangeNotifier {
  MvcStateValue(this.value, {required this.controller});
  final MvcController controller;
  T value;

  void update() => notifyListeners();

  Set<MvcStateValue> _dependentStates = {};
  FutureOr _dependentStateListener() {
    update();
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

class MvcDependentBuilderStateValue<T> extends MvcStateValue<T> {
  MvcDependentBuilderStateValue(super.value, {required this.builder, required super.controller});

  final FutureOr<T> Function(T state) builder;
  @override
  FutureOr _dependentStateListener() async {
    var buildValue = builder(value);
    value = buildValue is T ? buildValue : (await buildValue);
    update();
  }
}

class MvcStateValueTransformer<T, E> extends MvcStateValue<T> {
  MvcStateValueTransformer(super.value, this._source, this._transformer, {required super.controller}) {
    updateDependentStates({_source});
  }
  @override
  FutureOr _dependentStateListener() async {
    var buildValue = _transformer(_source.value);
    value = buildValue is T ? buildValue : (await buildValue);
    update();
  }

  final MvcStateValue<E> _source;
  final FutureOr<T> Function(E state) _transformer;
}
