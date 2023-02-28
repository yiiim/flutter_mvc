part of './flutter_mvc.dart';

/// 状态的访问级别
enum MvcStateAccessibility {
  /// 全局的，所有Controller都可以获取
  global,

  /// 公开的，当前Controller、Part和它的子级都可以获取
  public,

  /// 私有的，当前Controller和Part可以获取
  private,

  /// 内部的，Controller创建的仅可通过Controller获取，通过Part创建的仅可通过Part获取
  internal,
}

/// 在字典中保存状态的值
class _MvcControllerStateValue<T> {
  _MvcControllerStateValue({required this.value, this.accessibility = MvcStateAccessibility.public});
  final MvcStateValue<T> value;
  final MvcStateAccessibility accessibility;
}

/// 在字典中保存状态的键
class _MvcControllerStateKey {
  _MvcControllerStateKey({required this.stateType, this.key});
  final Type stateType;
  final Object? key;

  @override
  int get hashCode => Object.hashAll([stateType, key]);

  @override
  bool operator ==(Object other) {
    return other is _MvcControllerStateKey && stateType == other.stateType && other.key == key;
  }
}

class MvcControllerState {
  MvcControllerState(this.controller, {this.controllerPart});

  /// 全部的状态
  final Map<_MvcControllerStateKey, _MvcControllerStateValue> _internalState = HashMap<_MvcControllerStateKey, _MvcControllerStateValue>();

  /// 获取状态的最终方法
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅从当前state获取
  /// [originController]最开始获取状态的Controller
  /// [originPart]最开始获取状态的Part
  _MvcControllerStateValue<T>? _getControllerStateValue<T>(_MvcControllerStateKey key, {bool onlySelf = false, required MvcController originController, MvcControllerPart? originPart}) {
    var stateValue = _internalState[key] as _MvcControllerStateValue<T>?;
    if (stateValue == null && controllerPart == null) {
      for (var element in controller._typePartsMap.values) {
        if (element == originPart) continue;
        stateValue = element._state._getControllerStateValue(key, onlySelf: true, originController: originController, originPart: element);
        if (stateValue != null) break;
      }
    }
    if (stateValue != null) {
      if (stateValue.accessibility == MvcStateAccessibility.global) return stateValue;
      if (stateValue.accessibility == MvcStateAccessibility.public) return stateValue;
      if (stateValue.accessibility == MvcStateAccessibility.private && originController == controller) return stateValue;
      if (stateValue.accessibility == MvcStateAccessibility.internal && originController == controller && ((originPart == null && controllerPart == null) || originPart == controllerPart)) return stateValue;
    }
    if (!onlySelf) {
      if (originPart != null && originPart == controllerPart) return originPart.controller._state._getControllerStateValue(key, originController: originController);
      return controller.parent()?._state._getControllerStateValue<T>(key, originController: originController, originPart: originPart);
    }
    return null;
  }

  /// 当前状态所属的Controller
  final MvcController controller;

  /// 如果不为null，则表示这是一个Part的状态
  final MvcControllerPart? controllerPart;

  /// 初始化一个状态值
  ///
  /// [stateValue]状态值
  /// [key]名称
  /// [accessibility]状态访问级别
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initStateValue<T>(MvcStateValue<T> stateValue, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    _MvcControllerStateKey stateKey = _MvcControllerStateKey(stateType: T, key: key);
    assert(_internalState.containsKey(stateKey) == false, "创建了重复的状态类型,你可以使用key区分状态");
    assert(accessibility != MvcStateAccessibility.global || MvcOwner.sharedOwner._globalState.containsKey(stateKey) == false, "创建了重复的全局状态类型,你可以使用key区分状态");
    if (accessibility == MvcStateAccessibility.global) {
      MvcOwner.sharedOwner._globalState[stateKey] = stateValue;
    }
    _internalState[stateKey] = _MvcControllerStateValue<T>(value: stateValue, accessibility: accessibility);
    return stateValue;
  }

  /// 初始化状态
  ///
  /// [state]状态初始值
  /// [key]名称
  /// [accessibility]状态访问级别
  /// 状态依靠[key]和[T]确定为同一状态，初始化状态时，同一Controller内确保[key]+[T]唯一
  MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    var stateValue = MvcStateValue<T>(state, controller: controller);
    return initStateValue<T>(stateValue, key: key, accessibility: accessibility);
  }

  /// 更新状态，如果状态不存在则返回null
  ///
  /// [updater]更新状态的方法，即使没有[updater]状态也会更新
  /// [key]要更新状态的key
  /// [onlySelf]是否仅在当前Controller获取
  MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key, bool onlySelf = true}) {
    var s = getStateValue<T>(key: key, onlySelf: onlySelf);
    if (s != null) updater?.call(s);
    s?.update();
    return s;
  }

  /// 获取状态值
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  MvcStateValue<T>? getStateValue<T>({Object? key, bool onlySelf = false}) {
    var value = _getControllerStateValue<T>(_MvcControllerStateKey(stateType: T, key: key), onlySelf: onlySelf, originController: controller, originPart: controllerPart)?.value ?? MvcOwner.sharedOwner.getGlobalStateValue<T>(key: key);
    return value;
  }

  /// 获取状态
  ///
  /// [key]状态的key
  /// [onlySelf]是否仅在当前Controller或当前Part获取
  T? getState<T>({Object? key, bool onlySelf = false}) => getStateValue<T>(key: key, onlySelf: onlySelf)?.value;

  void dispose() {
    for (var element in _internalState.keys) {
      if (_internalState[element]!.accessibility == MvcStateAccessibility.global) {
        MvcOwner.sharedOwner._globalState.remove(element);
      }
      _internalState[element]?.value.dispose();
    }
  }

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
  MvcStateValue<T>? initLinkedState<T>({Object? key, bool onlySelf = false, Object? linkedToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) => initTransformState<T, T>((e) => e, key: key, onlySelf: onlySelf, transformToKey: linkedToKey, accessibility: accessibility);

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
  MvcStateValue<T>? initTransformState<T, E>(FutureOr<T> Function(E state) transformer, {T Function()? initialStateBuilder, Object? key, bool onlySelf = false, Object? transformToKey, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
    var state = getStateValue<E>(key: key, onlySelf: onlySelf);
    if (state != null) {
      late T initialState;
      if (initialStateBuilder != null) {
        initialState = initialStateBuilder();
      } else {
        var transformerState = transformer(state.value);
        if (transformerState is T) {
          initialState = transformerState;
        } else {
          throw "if transformer return future, must provider initialStateBuilder";
        }
      }
      var stateValue = MvcStateValueTransformer<T, E>(initialState, state, transformer, controller: controller);
      return initStateValue<T>(stateValue, key: key, accessibility: accessibility);
    }
    return null;
  }

  /// 初始化一个根据其他状态而生成的状态
  ///
  /// [initialStateBuilder]初始状态提供方法，如果为空，则初始状态直接调用[builder]获得，如果[builder]是异步的，此项不能为空
  /// [builder]状态值构建者，每次该状态更新时执行，并将状态值设置为返回值
  /// [dependent]依赖的状态，任何依赖的状态更新，都将触发该状态更新
  /// [key]状态的key
  /// [accessibility]状态访问级别
  MvcStateValue<T> initDependentBuilderState<T>(FutureOr<T> Function() builder, {Set<MvcStateValue> dependent = const {}, T Function()? initialStateBuilder, Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public}) {
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
    var stateValue = MvcDependentBuilderStateValue<T>(initialState, builder: builder, controller: controller)..updateDependentStates(dependent);
    return initStateValue<T>(stateValue, key: key, accessibility: accessibility);
  }
}