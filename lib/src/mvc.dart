part of './flutter_mvc.dart';

class MvcOwner extends EasyTreeRelationOwner {
  static final MvcOwner sharedOwner = MvcOwner();
  final Map<MvcStateKey, MvcStateValue> _globalState = HashMap<MvcStateKey, MvcStateValue>();
  T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => getAll(context: context, where: where).firstOrNull;

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
        if (element._controller is T && (where?.call(element._controller as T) ?? true)) yield element._controller as T;
        element = element.easyTreeGetParent(EasyTreeNodeKey<Type>(T));
      }
    }
  }

  T? getSingle<T extends MvcController>() {
    return (easyTreeGetChildInAll(EasyTreeNodeKey<MvcSingleEasyTreeNodeKeyValue>(MvcSingleEasyTreeNodeKeyValue(T))) as MvcElement?)?._controller as T?;
  }

  MvcStateValue<T>? getGlobalStateValue<T>({Object? key}) {
    return _globalState[MvcStateKey(stateType: T, key: key)] as MvcStateValue<T>?;
  }
}

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends Widget {
  const Mvc({required this.creater, TModelType? model, Key? key})
      : model = model ?? model as TModelType,
        super(key: key);
  final TControllerType Function() creater;
  final TModelType model;
  static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => MvcOwner.sharedOwner.get<T>(context: context, where: where);
  static Iterable<T> getAll<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => MvcOwner.sharedOwner.getAll<T>(context: context, where: where);
  static T? getSingle<T extends MvcController>() => MvcOwner.sharedOwner.getSingle<T>();

  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, creater);
}

/// 控制器单例
///
/// 单例表示如果当前已经存在[TControllerType]类型并且被指定为单例的控制器，则直接使用这个控制器，不在另外创建
/// 需要注意单例类型为[TControllerType]，在使用的需要指定确定的[TControllerType]
class MvcSingle<TControllerType extends MvcController<TModelType>, TModelType> extends Mvc<TControllerType, TModelType> {
  const MvcSingle({required super.creater, super.model, super.key});
  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, creater, single: true);
}

/// 控制器代理
///
/// 控制器代理表示控制器没有View，使用child作为view
/// 这在使用只有逻辑的控制器时很有用
class MvcProxy<TProxyControllerType extends MvcProxyController> extends StatelessWidget {
  const MvcProxy({Key? key, required this.child, required this.proxyCreater}) : super(key: key);
  final Widget child;
  final TProxyControllerType Function() proxyCreater;
  @override
  Widget build(BuildContext context) => Mvc(creater: proxyCreater, model: child);
}

/// 多个控制器代理
class MvcMultiProxy extends StatelessWidget {
  const MvcMultiProxy({Key? key, required this.child, required this.proxyCreater}) : super(key: key);
  final Widget child;
  final List<MvcProxyController Function()> proxyCreater;
  @override
  Widget build(BuildContext context) {
    var widget = child;
    for (var element in proxyCreater) {
      widget = Mvc(creater: element, model: widget);
    }
    return widget;
  }
}

/// 控制器代理单例
///
/// 只在提供只有逻辑的单例控制器时很有用
class MvcSingleProxy<TProxyControllerType extends MvcProxyController> extends StatelessWidget {
  const MvcSingleProxy({Key? key, required this.child, required this.singleProxyCreater}) : super(key: key);
  final Widget child;
  final TProxyControllerType Function() singleProxyCreater;
  @override
  Widget build(BuildContext context) => MvcSingle(creater: singleProxyCreater, model: child);
}
