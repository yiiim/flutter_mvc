part of './flutter_mvc.dart';

abstract class MvcControllerContext {
  /// 从父级查找指定类型的Controller
  T? parent<T extends MvcController>();

  /// 在直接子级查找指定类型的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? child<T extends MvcController>({bool sort = false});

  /// 从所有子级中查找指定类型的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? find<T extends MvcController>({bool sort = false});

  /// 在同级中查找前面的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? previousSibling<T extends MvcController>({bool sort = false});

  /// 在同级中查找后面的Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? nextSibling<T extends MvcController>({bool sort = false});

  /// 在同级中查找Controller
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  /// [includeSelf]表示是否包含自己本身
  T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false});

  /// 向前查找，表示查找同级前面的和父级，相当于[previousSibling]??[parent]
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? forward<T extends MvcController>({bool sort = false});

  /// 向后查找，表示查找同级后面的和子级，相当于[nextSibling]??[find]
  ///
  /// [sort]表示是否保证在树中正确的顺序，保证顺序速度较慢，如果不保证顺序则使用挂载顺序
  T? backward<T extends MvcController>({bool sort = false});
}

abstract class MvcContext<TControllerType extends MvcController<TModelType>, TModelType> implements MvcControllerContext {
  TControllerType get controller;
  TModelType get model;
  BuildContext get buildContext;
}

// class _MvcProxyContext<TControllerType extends MvcController<TModelType>, TModelType> extends MvcContext<TControllerType, TModelType> {
//   _MvcProxyContext(this.context) {
//     assert(context.controller is TControllerType);
//   }
//   final MvcContext context;
//   @override
//   T? parent<T extends MvcController>() => context.parent<T>();
//   @override
//   T? child<T extends MvcController>({bool sort = false}) => context.child<T>(sort: sort);
//   @override
//   T? find<T extends MvcController>({bool sort = false}) => context.find<T>(sort: sort);
//   @override
//   T? previousSibling<T extends MvcController>({bool sort = false}) => context.previousSibling<T>(sort: sort);
//   @override
//   T? nextSibling<T extends MvcController>({bool sort = false}) => context.nextSibling<T>(sort: sort);
//   @override
//   T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) => context.sibling<T>(sort: sort, includeSelf: includeSelf);
//   @override
//   T? forward<T extends MvcController>({bool sort = false}) => context.forward<T>(sort: sort);
//   @override
//   T? backward<T extends MvcController>({bool sort = false}) => context.backward<T>(sort: sort);
//   @override
//   TControllerType get controller => context.controller as TControllerType;
//   @override
//   BuildContext get buildContext => context.buildContext;
//   @override
//   TModelType get model => context.model;
// }
