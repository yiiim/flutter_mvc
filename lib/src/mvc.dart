part of './flutter_mvc.dart';

class MvcOwner extends EasyTreeRelationOwner with DependencyInjectionService, MvcStateProviderMixin {
  static final MvcOwner sharedOwner = MvcOwner();
  late final MvcServiceCollection _serviceCollection = MvcServiceCollection()
    ..addSingleton<MvcOwner>((serviceProvider) => this, initializeWhenServiceProviderBuilt: true)
    ..add<ServiceCollection>((serviceProvider) => MvcServiceCollection());
  MvcServiceCollection get serviceCollection => _serviceCollection;
  ServiceProvider? _serviceProvider;
  @override
  ServiceProvider get serviceProvider {
    _serviceProvider ??= serviceCollection.build();
    return _serviceProvider!;
  }

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
        if (element._controller is T && (where?.call(element._controller as T) ?? true)) {
          yield element._controller as T;
        }

        element = element.easyTreeGetParent(EasyTreeNodeKey<Type>(T));
      }
    }
  }
}

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends Widget {
  // ignore: prefer_const_constructors_in_immutables
  Mvc({this.create, TModelType? model, Key? key})
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
