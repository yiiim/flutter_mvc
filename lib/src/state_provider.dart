part of './flutter_mvc.dart';

/// 状态提供接口
abstract class MvcStateProvider {
  /// 获取状态
  ///
  /// [key] 状态key
  T? getState<T>({Object? key});

  /// 获取状态值
  ///
  /// [key] 状态key
  MvcStateValue<T>? getStateValue<T>({Object? key});
}

/// Widget状态提供接口
abstract class MvcWidgetStateProvider<TControllerType extends MvcController> {
  /// 当前build的[BuildContext]
  BuildContext get context;

  /// 关联的Controller， 通常时Widget最近的指定类型的[MvcController]
  TControllerType get controller;

  /// 获取状态
  ///
  /// [key] 状态key
  T? get<T>({Object? key});

  /// 获取状态值
  ///
  /// [key] 状态key
  MvcStateValue<T>? getValue<T>({Object? key});

  /// 获取分部状态提供接口
  ///
  /// [MvcStateProvider]分部状态的类型
  MvcWidgetStateProvider? part<T extends MvcControllerPart>();
}
