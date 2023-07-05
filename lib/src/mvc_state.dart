part of './flutter_mvc.dart';

class _MvcStateKey {
  _MvcStateKey({required this.stateType, this.key});
  final Type stateType;
  final Object? key;

  @override
  int get hashCode => Object.hashAll([stateType, key]);

  @override
  bool operator ==(Object other) {
    return other is _MvcStateKey && stateType == other.stateType && other.key == key;
  }
}

/// with这个mixin就可以成为一个[MvcStateProvider]
mixin MvcStateProviderMixin implements MvcStateProvider {
  /// 全部的状态
  final Map<Object, MvcStateValue> _internalState = HashMap<Object, MvcStateValue>();

  /// 初始化一个状态值
  ///
  /// [stateValue]状态值
  /// [key]名称
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initStateValue<T>(MvcStateValue<T> stateValue, {Object? key}) {
    _MvcStateKey stateKey = _MvcStateKey(stateType: T, key: key);
    assert(_internalState.containsKey(stateKey) == false, "State has been initialized");
    _internalState[stateKey] = stateValue;
    return stateValue;
  }

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key}) => initStateValue(MvcStateValue<T>(state), key: key);

  /// 更新状态，如果状态不存在则返回null
  ///
  /// [updater]更新状态的方法，即使没有[updater]状态也会更新
  /// [key]要更新状态的key
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key}) {
    var s = getStateValue<T>(key: key);
    if (s != null) updater?.call(s);
    s?.update();
    return s;
  }

  /// 获取状态值
  ///
  /// [key]状态的key
  @override
  MvcStateValue<T>? getStateValue<T>({Object? key}) {
    return _internalState[_MvcStateKey(stateType: T, key: key)] as MvcStateValue<T>?;
  }

  /// 删除状态
  void deleteState<T>({Object? key}) {
    _internalState.remove(_MvcStateKey(stateType: T, key: key));
  }
}
