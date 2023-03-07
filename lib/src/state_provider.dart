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

/// 具有分部的状态提供接口
abstract class MvcHasPartStateProvider extends MvcStateProvider {
  /// 获取指定类型的状态分部
  T? getStatePart<T extends MvcStateProvider>();
}

/// Widget状态提供接口
abstract class MvcWidgetStateProvider {
  /// 当前build的[BuildContext]
  BuildContext get context;

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
  MvcWidgetStateProvider? part<T extends MvcStateProvider>();

  /// 有状态更新时不需要更新的[Widget]
  ///
  /// 在Mvc中是[MvcStateScope]的child
  Widget? get child;
}
