part of './flutter_mvc.dart';

/// 状态值
class MvcStateValue<T> extends ChangeNotifier {
  MvcStateValue(this.value, {required this.controller});
  final MvcController controller;
  T value;

  void update() => notifyListeners();
}

/// 可以依赖其他状态更新而更新的状态值
class MvcDependentStateValue<T> extends MvcStateValue<T> {
  MvcDependentStateValue(super.value, {required super.controller});

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

/// 一个可依赖其他状态而更新的状态，依赖状态更新时执行[builder]返回新的状态值
class MvcDependentBuilderStateValue<T> extends MvcDependentStateValue<T> {
  MvcDependentBuilderStateValue(super.value, {required this.builder, required super.controller});

  final FutureOr<T> Function(MvcStateValue<T>) builder;
  @override
  FutureOr _dependentStateListener() async {
    var buildValue = builder(this);
    value = buildValue is T ? buildValue : (await buildValue);
    super._dependentStateListener();
  }
}

/// 转换另外一个状态
class MvcStateValueTransformer<T, E> extends MvcDependentStateValue<T> {
  MvcStateValueTransformer(super.value, this._source, this._transformer, {required super.controller}) {
    updateDependentStates({_source});
  }
  @override
  FutureOr _dependentStateListener() async {
    var buildValue = _transformer(_source.value);
    value = buildValue is T ? buildValue : (await buildValue);
    super._dependentStateListener();
  }

  final MvcStateValue<E> _source;
  final FutureOr<T> Function(E state) _transformer;
}
