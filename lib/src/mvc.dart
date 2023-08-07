part of './flutter_mvc.dart';

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends Widget {
  const Mvc({this.create, TModelType? model, Key? key})
      : model = model ?? model as TModelType,
        super(key: key);
  final TControllerType Function()? create;
  final TModelType model;

  static T? get<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => MvcOwner.sharedOwner.get<T>(context: context, where: where);
  static Iterable<T> getAll<T extends MvcController>({BuildContext? context, bool Function(T controller)? where}) => MvcOwner.sharedOwner.getAll<T>(context: context, where: where);

  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, create);
}

typedef ModellessMvc<TControllerType extends MvcController> = Mvc<TControllerType, dynamic>;

/// 控制器代理
///
/// 控制器代理表示控制器没有View，使用child作为view
/// 这在使用只有逻辑的控制器时很有用
class MvcProxy<TProxyControllerType extends MvcProxyController> extends StatelessWidget {
  const MvcProxy({Key? key, required this.proxyCreate, required this.child}) : super(key: key);
  final Widget child;
  final TProxyControllerType Function() proxyCreate;
  @override
  Widget build(BuildContext context) => Mvc(create: proxyCreate, model: child);
}

/// 多个控制器代理
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
