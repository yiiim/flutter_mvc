part of './flutter_mvc.dart';

/// 一些易用的拓展方法
extension MvcControllerStateMixinExtension on MvcControllerStateMixin {
  /// 如果状态不存在则初始化状态，
  MvcStateValue<T> initIfNeedState<T>(T Function() stateCreator, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    return _state.getStateValue<T>(key: key, onlySelf: true) ?? initState(stateCreator(), key: key, accessibility: accessibility);
  }

  /// 初始化一个链接状态
  /// 链接状态的值和被的连接状态保持一致，这其实相当于一个拷贝操作
  /// 如果被链接的状态发生更新，则这个状态也将更新
  /// 这其实是[initTransformState]不做任何转换
  ///
  /// [T]要链接状态的类型
  /// [key]要链接的状态的key
  /// [onlySelf]获取要链接的状态时，是否仅从自身获取，仅从自身获取表示不从父级获取
  /// [linkedToKey]链接之后的key
  /// [accessibility]链接之后的状态访问级别
  MvcStateValue<T>? initLinkedState<T>({Object? key, bool onlySelf = false, Object? linkedToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    return initTransformState<T, T>((e) => e, key: key, onlySelf: onlySelf, transformToKey: linkedToKey, accessibility: accessibility);
  }

  /// 初始化一个转换状态
  /// 将指定状态转换为新的状态
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// [T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [key]要链接的状态的key
  /// [onlySelf]获取要链接的状态时，是否仅从自身获取，仅从自身获取表示不从父级获取
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[transformer]获得，如果[transformer]是异步的，此项不能为空
  /// [transformToKey]转换之后的key
  /// [accessibility]转换之后的状态访问级别
  MvcStateValue<T>? initTransformState<T, E>(FutureOr<T> Function(E state) transformer, {Object? key, bool onlySelf = false, T Function()? initialStateBuilder, Object? transformToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    var transformState = getStateValue<E>(key: key, onlySelf: onlySelf);
    if (transformState != null) {
      return initStateValueTransformState(transformer, transformState, initialStateBuilder: initialStateBuilder, transformToKey: transformToKey, accessibility: accessibility);
    }
    return null;
  }

  /// 初始化一个指定状态的转换状态
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// [T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [transformState]要转换的状态
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[transformer]获得，如果[transformer]是异步的，此项不能为空
  /// [transformToKey]转换之后的key
  /// [accessibility]转换之后的状态访问级别
  MvcStateValue<T> initStateValueTransformState<T, E>(FutureOr<T> Function(E state) transformer, MvcStateValue<E> transformState, {T Function()? initialStateBuilder, Object? transformToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    late T initialState;
    if (initialStateBuilder != null) {
      initialState = initialStateBuilder();
    } else {
      var transformerState = transformer(transformState.value);
      if (transformerState is T) {
        initialState = transformerState;
      } else {
        throw "if transformer return future, must provider initialStateBuilder";
      }
    }
    var stateValue = MvcStateValueTransformer<T, E>(initialState, transformState, transformer);
    return initStateValue<T>(stateValue, key: transformToKey, accessibility: accessibility);
  }

  /// 初始化一个根据其他状态而生成的状态
  ///
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[builder]获得，如果[builder]是异步的，此项不能为空
  /// [builder]状态值构建者，每次该状态更新时执行，并将状态值设置为返回值
  /// [dependent]依赖的状态，任何依赖的状态更新，都将触发该状态更新
  /// [key]状态的key
  /// [accessibility]状态访问级别
  MvcStateValue<T> initDependentBuilderState<T>(
    FutureOr<T> Function() builder, {
    Set<MvcStateValue> dependent = const {},
    T Function()? initialStateBuilder,
    Object? key,
    MvcStateAccessibility accessibility = MvcStateAccessibility.public,
  }) {
    late T initialState;
    if (initialStateBuilder != null) {
      initialState = initialStateBuilder();
    } else {
      var transformerState = builder();
      if (transformerState is T) {
        initialState = transformerState;
      } else {
        throw "if transformer return future, must provider initialStateBuilder";
      }
    }
    var stateValue = MvcDependentBuilderStateValue<T>(initialState, builder: (s) => builder())..updateDependentStates(dependent);
    return initStateValue<T>(stateValue, key: key, accessibility: accessibility);
  }

  /// 初始化依赖其他状态的状态
  ///
  /// [state]初始状态值
  /// [updater]更新器，每次依赖状态更新时都会执行的方法，并且执行完成之后触发状态更新
  /// [dependent]依赖的状态，任何依赖的状态更新，都将触发该状态更新
  /// [key]状态的key
  /// [accessibility]状态访问级别
  MvcStateValue<T> initDependentState<T>(
    T state, {
    FutureOr Function(MvcStateValue<T> state)? updater,
    Set<MvcStateValue> dependent = const {},
    Object? key,
    MvcStateAccessibility accessibility = MvcStateAccessibility.public,
  }) {
    var stateValue = MvcDependentBuilderStateValue<T>(
      state,
      builder: (state) {
        var updateResult = updater?.call(state);
        if (updateResult is Future) return Future.value(state.value);
        return state.value;
      },
    )..updateDependentStates(dependent);
    return initStateValue<T>(stateValue, key: key, accessibility: accessibility);
  }

  /// 使用指定值更新状态，如果状态不存在则初始化状态
  ///
  /// [state]要更新或者初始化的状态
  /// [key]名称
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  MvcStateValue<T> updateStateInitIfNeed<T>(T state, {Object? key, bool onlySelf = true}) {
    var s = _state.getStateValue<T>(key: key, onlySelf: onlySelf);
    s ??= _state.initState<T>(state, key: key);
    s.value = state;
    s.update();
    return s;
  }
}

extension MvcControllerStateExtension on MvcController {
  /// 初始化一个链接状态,并且被链接状态从指定的Part类型获取
  /// 链接状态的值和被的连接状态保持一致，这其实相当于一个拷贝操作
  /// 如果被链接的状态发生更新，则这个状态也将更新
  /// 这其实是[initTransformState]不做任何转换
  ///
  /// [TPartType]Part的类型，[T]要链接状态的类型
  /// [key]要链接的状态的key
  /// [onlySelf]获取要链接的状态时，是否仅从自身获取，仅从自身获取表示不从父级获取
  /// [linkedToKey]链接之后的key
  /// [accessibility]链接之后的状态访问级别
  MvcStateValue<T>? initPartLinkedState<TPartType, T>({Object? key, bool onlySelf = false, Object? linkedToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    var transformState = part<MvcControllerPart>()?.getStateValue<T>(key: key, onlySelf: onlySelf);
    if (transformState != null) {
      return initStateValueTransformState<T, T>((state) => state, transformState, transformToKey: linkedToKey, accessibility: accessibility);
    }
    return null;
  }

  /// 初始化一个转换状态,并且被转换状态从指定的Part类型获取
  /// 将指定状态转换为新的状态
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// [TPartType]Part的类型，[T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [key]要链接的状态的key
  /// [onlySelf]获取要链接的状态时，是否仅从自身获取，仅从自身获取表示不从父级获取
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[transformer]获得，如果[transformer]是异步的，此项不能为空
  /// [transformToKey]转换之后的key
  /// [accessibility]转换之后的状态访问级别
  MvcStateValue<T>? initPartTransformState<TPartType, T, E>(FutureOr<T> Function(E state) transformer, {Object? key, bool onlySelf = false, T Function()? initialStateBuilder, Object? transformToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    var transformState = part<MvcControllerPart>()?.getStateValue<E>(key: key, onlySelf: onlySelf);
    if (transformState != null) {
      return initStateValueTransformState<T, E>(transformer, transformState, initialStateBuilder: initialStateBuilder, transformToKey: transformToKey, accessibility: accessibility);
    }
    return null;
  }
}
