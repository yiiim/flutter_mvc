part of './flutter_mvc.dart';

class MvcOwner extends EasyTreeRelationOwner {
  static final MvcOwner sharedOwner = MvcOwner();
  final Map<_MvcControllerStateKey, MvcStateValue> _globalState = HashMap<_MvcControllerStateKey, MvcStateValue>();
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

  MvcStateValue<T>? getGlobalStateValue<T>({Object? key}) {
    return _globalState[_MvcControllerStateKey(stateType: T, key: key)] as MvcStateValue<T>?;
  }
}

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends Widget {
  const Mvc({required this.create, TModelType? model, Key? key})
      : model = model ?? model as TModelType,
        super(key: key);
  final TControllerType Function() create;
  final TModelType model;
  static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => MvcOwner.sharedOwner.get<T>(context: context, where: where);
  static Iterable<T> getAll<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => MvcOwner.sharedOwner.getAll<T>(context: context, where: where);

  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, create);
}

/// ???????????????
///
/// ????????????????????????????????????View?????????child??????view
/// ????????????????????????????????????????????????
class MvcProxy<TProxyControllerType extends MvcProxyController> extends StatelessWidget {
  const MvcProxy({Key? key, required this.proxyCreate, required this.child}) : super(key: key);
  final Widget child;
  final TProxyControllerType Function() proxyCreate;
  @override
  Widget build(BuildContext context) => Mvc(create: proxyCreate, model: child);
}

/// ?????????????????????
class MvcMultiProxy extends StatelessWidget {
  const MvcMultiProxy({Key? key, required this.proxyCreate, required this.child}) : super(key: key);
  final Widget child;
  final List<MvcProxyController Function()> proxyCreate;
  @override
  Widget build(BuildContext context) {
    var widget = child;
    for (var element in proxyCreate) {
      widget = Mvc(create: element, model: widget);
    }
    return widget;
  }
}
