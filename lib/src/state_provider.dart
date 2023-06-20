part of './flutter_mvc.dart';

/// 状态提供接口
abstract class MvcStateProvider {
  /// 获取状态值
  ///
  /// [key] 状态key
  MvcStateValue<T>? getStateValue<T>({Object? key});
}

/// 上下文状态
abstract class MvcStateContext {
  /// 当前build的[BuildContext]
  BuildContext get context;

  /// 获取状态值
  ///
  /// [key] 状态key
  MvcStateValue<T>? getValue<T>({Object? key});
}

extension MvcStateProviderExtension on MvcStateProvider {
  /// 获取状态
  ///
  /// [key] 状态key
  T? getState<T>({Object? key}) => getStateValue<T>(key: key)?.value;
}

extension MvcStateContextExtension on MvcStateContext {
  /// 获取状态
  ///
  /// [key] 状态key
  T? get<T>({Object? key}) => getValue<T>(key: key)?.value;
}
