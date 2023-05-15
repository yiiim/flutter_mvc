part of './flutter_mvc.dart';

/// 状态提供接口
abstract class MvcStateProvider {
  /// 获取状态值
  ///
  /// [key] 状态key
  MvcStateValue<T>? getStateValue<T>({Object? key});
}

extension MvcStateProviderExtension on MvcStateProvider {
  /// 获取状态
  ///
  /// [key] 状态key
  T? getState<T>({Object? key}) => getStateValue(key: key)?.value;
}

/// Widget状态提供接口
abstract class MvcWidgetStateProvider {
  /// 当前build的[BuildContext]
  BuildContext get context;

  /// 获取状态值
  ///
  /// [key] 状态key
  MvcStateValue<T>? getValue<T>({Object? key});

  /// 有状态更新时不需要更新的[Widget]
  ///
  /// 在Mvc中是[MvcStateScope]的child
  Widget? get child;
}

extension MvcWidgetStateProviderExtension on MvcWidgetStateProvider {
  /// 获取状态
  ///
  /// [key] 状态key
  T? get<T>({Object? key}) => getValue(key: key)?.value;
}
