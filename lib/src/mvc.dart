part of './flutter_mvc.dart';

class MvcOwner extends EasyTreeRelationOwner {
  static final MvcOwner sharedOwner = MvcOwner();
  final Map<MvcStateKey, MvcStateValue> _globalState = HashMap<MvcStateKey, MvcStateValue>();
  T? get<T extends MvcController>({BuildContext? context}) {
    if (context == null) return (easyTreeGetChildInAll(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    var element = EasyTreeElement.getEasyTreeElementFromContext(context, easyTreeOwner: this);
    var controller = (element as MvcElement?)?._controller;
    if (controller is T) return controller;
    return controller?.parent<T>();
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
  static T? get<T extends MvcController>({BuildContext? context}) => MvcOwner.sharedOwner.get<T>(context: context);
  static T? getSingle<T extends MvcController>() => MvcOwner.sharedOwner.getSingle<T>();

  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, creater);
}

/// 控制器单例
///
/// 单例表示如果当前已经存在[TControllerType]类型并且被指定为单例的控制器，则直接使用这个控制器，不在另外创建
/// 需要注意的是使用单例时必须要指定具体的[TControllerType]泛型类型
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
