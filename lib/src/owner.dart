part of './flutter_mvc.dart';

class MvcOwner extends EasyTreeRelationOwner with MvcStateProviderMixin {
  MvcOwner._internal({ServiceProvider? parentServiceProvider}) : serviceProvider = _buildMvcServiceProvider(parentServiceProvider: parentServiceProvider) {
    _sharedOwner = this;
  }
  static MvcOwner? _sharedOwner;
  static MvcOwner get sharedOwner {
    _sharedOwner ??= MvcOwner._internal();
    return _sharedOwner!;
  }

  static ServiceProvider _buildMvcServiceProvider({ServiceProvider? parentServiceProvider}) {
    MvcServiceCollection collection = MvcServiceCollection();
    collection.add<ServiceCollection>((serviceProvider) => MvcServiceCollection());
    if (parentServiceProvider != null) {
      return collection.buildScoped(parentServiceProvider);
    }
    return collection.build();
  }

  final ServiceProvider serviceProvider;

  /// 获取当前所有Mvc中[T]类型的MvcController
  ///
  /// [context]为null时，将会获取所有Mvc中的[T]类型的MvcController，否则获取离[context]最近的Mvc中的[T]类型的MvcController
  /// [where]为null时，将会获取所有Mvc中的[T]类型的MvcController，否则获取满足[where]条件的Mvc中的[T]类型的MvcController
  T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => getAll(context: context, where: where).firstOrNull;

  /// 获取当前所有Mvc中[T]类型的MvcController
  ///
  /// [context]为null时，将会获取所有Mvc中的[T]类型的MvcController，否则获取离[context]最近的Mvc中的[T]类型的MvcController
  /// [where]为null时，将会获取所有Mvc中的[T]类型的MvcController，否则获取满足[where]条件的Mvc中的[T]类型的MvcController
  Iterable<T> getAll<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) sync* {
    if (context == null) {
      var nodes = (easyTreeGetChildrenInAll(EasyTreeNodeKey<Type>(T))).where((element) => where?.call(element as T) ?? true);
      for (var item in nodes) {
        if (item is MvcElement && item._controller is T) {
          yield (item._controller as T);
        }
      }
    } else {
      EasyTreeNode? element = EasyTreeElement.getEasyTreeElementFromContext(context, easyTreeOwner: this);
      while (element != null && element is MvcElement) {
        if (element._controller is T && (where?.call(element._controller as T) ?? true)) {
          yield element._controller as T;
        }

        element = element.easyTreeGetParent(EasyTreeNodeKey<Type>(T));
      }
    }
  }
}
