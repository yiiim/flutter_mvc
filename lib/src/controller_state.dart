part of './flutter_mvc.dart';

/// 状态提供者接口
abstract class MvcControllerEnvironmentStateProvider implements MvcStateProvider {}

/// Part状态提供者接口
abstract class MvcControllerPartStateProvider implements MvcStateProvider {}

/// Controller状态提供者
mixin MvcControllerStateProvider on MvcStateProviderMixin, DependencyInjectionService {
  /// 环境状态提供者, 在MvcController中默认为[MvcControllerEnvironment]
  MvcControllerEnvironmentStateProvider get environmentStateProvider;

  /// Part状态提供者, 在MvcController中默认为[MvcControllerPartManager]
  MvcControllerPartStateProvider get partStateProvider;

  /// 获取状态值
  ///
  /// [key]状态的key
  /// 先获取自己的状态，如果不存在则获取Part中的状态，如果不存在则获取环境状态
  @override
  MvcStateValue<T>? getStateValue<T>({Object? key}) {
    return super.getStateValue<T>(key: key) ?? partStateProvider.getStateValue<T>(key: key) ?? environmentStateProvider.getStateValue<T>(key: key);
  }
}

/// 一些易用的拓展方法
extension MvcControllerStateMixinExtension on MvcControllerStateProvider {
  /// 如果状态不存在则初始化状态，
  MvcStateValue<T> initStateIfNeed<T>(T Function() stateCreator, {Object? key}) {
    return getStateValue<T>(key: key) ?? initState(stateCreator(), key: key);
  }

  /// 初始化一个链接状态
  /// 链接状态的值和被的连接状态保持一致，这其实相当于一个拷贝操作
  /// 如果被链接的状态发生更新，则这个状态也将更新
  /// 这其实是[initTransformState]不做任何转换
  ///
  /// [T]要链接状态的类型
  /// [key]要链接的状态的key
  /// [linkedToKey]链接之后的key
  MvcStateValue<T>? initLinkedState<T>({Object? key, Object? linkedToKey}) {
    return initTransformState<T, T>((e) => e, key: key, transformToKey: linkedToKey);
  }

  /// 初始化一个转换状态
  /// 将指定状态转换为新的状态
  /// 转换后的状态依赖之前的状态更新而更新
  ///
  /// [T]要转换状态的类型 [E]转换之后的状态类型
  /// [transformer]转换方法
  /// [key]要链接的状态的key
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[transformer]获得，如果[transformer]是异步的，此项不能为空
  /// [transformToKey]转换之后的key
  MvcStateValue<T>? initTransformState<T, E>(FutureOr<T> Function(E state) transformer, {Object? key, T Function()? initialStateBuilder, Object? transformToKey}) {
    var transformState = getStateValue<E>(key: key);
    if (transformState != null) {
      return initStateValueTransformState(transformer, transformState, initialStateBuilder: initialStateBuilder, transformToKey: transformToKey);
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
  MvcStateValue<T> initStateValueTransformState<T, E>(FutureOr<T> Function(E state) transformer, MvcStateValue<E> transformState, {T Function()? initialStateBuilder, Object? transformToKey}) {
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
    return initStateValue<T>(stateValue, key: transformToKey);
  }

  /// 初始化一个根据其他状态而生成的状态
  ///
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[builder]获得，如果[builder]是异步的，此项不能为空
  /// [builder]状态值构建者，每次该状态更新时执行，并将状态值设置为返回值
  /// [dependent]依赖的状态，任何依赖的状态更新，都将触发该状态更新
  /// [key]状态的key
  MvcStateValue<T> initDependentBuilderState<T>(
    FutureOr<T> Function() builder, {
    Set<MvcStateValue> dependent = const {},
    T Function()? initialStateBuilder,
    Object? key,
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
    return initStateValue<T>(stateValue, key: key);
  }

  /// 初始化依赖其他状态的状态
  ///
  /// [state]初始状态值
  /// [updater]更新器，每次依赖状态更新时都会执行的方法，并且执行完成之后触发状态更新
  /// [dependent]依赖的状态，任何依赖的状态更新，都将触发该状态更新
  /// [key]状态的key
  MvcStateValue<T> initDependentState<T>(
    T state, {
    FutureOr Function(MvcStateValue<T> state)? updater,
    Set<MvcStateValue> dependent = const {},
    Object? key,
  }) {
    var stateValue = MvcDependentBuilderStateValue<T>(
      state,
      builder: (state) {
        var updateResult = updater?.call(state);
        if (updateResult is Future) return Future.value(state.value);
        return state.value;
      },
    )..updateDependentStates(dependent);
    return initStateValue<T>(stateValue, key: key);
  }

  /// 使用指定值更新状态，如果状态不存在则初始化状态
  ///
  /// [state]要更新或者初始化的状态
  /// [key]名称
  MvcStateValue<T> updateStateInitIfNeed<T>(T state, {Object? key}) {
    var s = getStateValue<T>(key: key);
    s ??= initState<T>(state, key: key);
    s.value = state;
    s.update();
    return s;
  }
}
