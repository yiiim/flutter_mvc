part of './flutter_mvc.dart';

mixin MvcControllerStateMixin implements MvcStateProvider {
  MvcControllerState get _state;

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// [accessibility]状态访问级别
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller或同一Part内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) => _state.initState(state, key: key, accessibility: accessibility);

  /// 初始化一个状态值
  ///
  /// [stateValue]状态值
  /// [key]名称
  /// [accessibility]状态访问级别
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initStateValue<T>(MvcStateValue<T> stateValue, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) => _state.initStateValue(stateValue, key: key, accessibility: accessibility);

  /// 获取状态
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  @override
  T? getState<T>({Object? key, bool onlySelf = false}) => _state.getState<T>(key: key, onlySelf: onlySelf);

  /// 获取状态值
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  @override
  MvcStateValue<T>? getStateValue<T>({Object? key, bool onlySelf = false}) => _state.getStateValue(key: key, onlySelf: onlySelf);

  /// 更新状态，如果状态不存在则返回null，存在则返回状态
  ///
  /// [updater]更新状态的方法，即使没有[updater]状态也会更新
  /// [key]要更新状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key}) => _state.updateState(updater: updater, key: key);

  /// 删除状态
  void deleteState<T>({Object? key}) => _state.deleteState<T>(key: key);
}
