part of './flutter_mvc.dart';

mixin MvcControllerStateMixin implements MvcStateStorage {
  MvcControllerState get _state;

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// [accessibility]状态访问级别
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller或同一Part内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) => _state.initState(state, key: key, accessibility: accessibility);

  /// 初始化一个链接状态,如果没有获取目标状态则返回null
  /// 链接状态的值和被的连接状态保持一致，这其实相当于一个拷贝操作
  /// 如果被链接的状态发生更新，则这个状态也将更新
  /// 这个操作相当于[initTransformState]不做任何转换
  ///
  /// [T]要链接状态的类型
  /// [key]要链接状态的key
  /// [onlySelf]获取要链接的状态时，是否仅在当前状态获取
  /// [linkedToKey]链接之后的key
  /// [accessibility]状态访问级别
  MvcStateValue<T>? initLinkedState<T>({
    Object? key,
    bool onlySelf = false,
    Object? linkedToKey,
    MvcStateAccessibility accessibility = MvcStateAccessibility.public,
  }) =>
      _state.initLinkedState(
        key: key,
        onlySelf: onlySelf,
        linkedToKey: linkedToKey,
        accessibility: accessibility,
      );

  /// 初始化一个转换状态,如果没有获取到目标状态则返回null
  /// 将指定状态转换为新的状态
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// [T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[transformer]获得，如果[transformer]是异步的，此项不能为空
  /// [key]被转换状态的key
  /// [onlySelf]获取被装换状态时，是否仅在当前控制器获取
  /// [transformToKey]转换之后的key
  /// [accessibility]状态访问级别
  MvcStateValue<T>? initTransformState<T, E>(
    FutureOr<T> Function(E state) transformer, {
    T Function()? initialStateBuilder,
    Object? key,
    bool onlySelf = false,
    Object? transformToKey,
    MvcStateAccessibility accessibility = MvcStateAccessibility.public,
  }) =>
      _state.initTransformState<T, E>(
        transformer,
        initialStateBuilder: initialStateBuilder,
        key: key,
        onlySelf: onlySelf,
        transformToKey: transformToKey,
        accessibility: accessibility,
      );

  MvcStateValue<T> initDependentBuilderState<T>(
    FutureOr<T> Function() builder, {
    Set<MvcStateValue> dependent = const {},
    T Function()? initialStateBuilder,
    Object? key,
    MvcStateAccessibility accessibility = MvcStateAccessibility.public,
  }) =>
      _state.initDependentBuilderState(builder, dependent: dependent, initialStateBuilder: initialStateBuilder, key: key, accessibility: accessibility);

  /// 更新状态，如果状态不存在则返回null，存在则返回状态
  ///
  /// [updater]更新状态的方法，即使没有[updater]状态也会更新
  /// [key]要更新状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key, bool onlySelf = true}) => _state.updateState(updater: updater, key: key, onlySelf: onlySelf);

  /// 使用指定值更新状态，如果状态不存在则初始化状态
  ///
  /// [state]要更新或者初始化的状态
  /// [key]名称
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  MvcStateValue<T> updateStateInitIfNeed<T>(T state, {Object? key, bool onlySelf = true}) {
    var s = _state.getStateValue<T>(key: key, onlySelf: onlySelf);
    s ??= _state.initState<T>(state, key: key);
    s.update();
    return s;
  }

  /// 获取状态
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  T? getState<T>({Object? key, bool onlySelf = false}) => _state.getState<T>(key: key, onlySelf: onlySelf);

  /// 获取状态值
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  MvcStateValue<T>? getStateValue<T>({Object? key, bool onlySelf = false}) => _state.getStateValue(key: key, onlySelf: onlySelf);
}
