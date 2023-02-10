part of './flutter_mvc.dart';

class MvcSingleEasyTreeNodeKeyValue {
  MvcSingleEasyTreeNodeKeyValue(this.controllerType);

  Type controllerType;

  @override
  int get hashCode => controllerType.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MvcSingleEasyTreeNodeKeyValue && other.controllerType == controllerType;
  }
}

class MvcElement<TControllerType extends MvcController<TModelType>, TModelType> extends EasyTreeRelationElement implements MvcContext<TControllerType, TModelType> {
  MvcElement(super.widget, TControllerType Function() creater, {this.single = false})
      : assert(single == false || TControllerType != MvcController, "当使用单例时，请指定泛型[TControllerType]具体的类型"),
        _controller = (() {
          if (!single) return creater();
          var existSingleController = MvcOwner.sharedOwner.getSingle<TControllerType>();
          return existSingleController ?? creater();
        }()),
        super(easyTreeOwner: MvcOwner.sharedOwner);

  final TControllerType _controller;
  final bool single;

  @override
  void update(covariant Widget newWidget) {
    var oldWidget = widget;
    super.update(newWidget);
    if ((oldWidget as Mvc<TControllerType, TModelType>?)?.model != (newWidget as Mvc<TControllerType, TModelType>?)?.model) {
      _controller.updateState<TModelType>(updater: (state) => state?.value = (widget as Mvc<TControllerType, TModelType>).model, key: _controller._element == this ? null : this);
    }
  }

  @override
  void mountEasyTree(EasyTreeNode? parent) {
    super.mountEasyTree(parent);
    _controller.addListener(markNeedsBuild);
    _controller.initState<TModelType>((widget as Mvc<TControllerType, TModelType>).model, key: _controller._element == null ? null : this);
    _controller._initForElement(this);
  }

  @override
  void activate() {
    super.activate();
    _controller._activateForElement(this);
  }

  @override
  void unmount() {
    super.unmount();
    _controller.removeListener(markNeedsBuild);
    _controller._disposeForElement(this);
  }

  @override
  T? parent<T extends MvcController>() => (easyTreeGetParent(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  @override
  T? child<T extends MvcController>({bool sort = false}) {
    if (sort) return (easyTreeGetSortedChild(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    return (easyTreeGetChild(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? find<T extends MvcController>({bool sort = false}) {
    if (sort) return (easyTreeGetSortedChildInAll(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    return (easyTreeGetChildInAll(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? previousSibling<T extends MvcController>({bool sort = false}) {
    if (sort) return (easyTreeGetSortedPreviousSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    return (easyTreeGetPreviousSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? nextSibling<T extends MvcController>({bool sort = false}) {
    if (sort) return (easyTreeGetSortedNextSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    return (easyTreeGetNextSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? sibling<T extends MvcController>({bool sort = false, bool includeSelf = false}) {
    if (sort) return (easyTreeGetSortedSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    return (easyTreeGetSibling(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
  }

  @override
  T? forward<T extends MvcController>({bool sort = false}) => previousSibling<T>(sort: sort) ?? parent<T>();

  @override
  T? backward<T extends MvcController>({bool sort = false}) => nextSibling<T>(sort: sort) ?? find<T>(sort: sort);

  @override
  List<EasyTreeNodeKey> get keys => [
        EasyTreeNodeKey<Type>(_controller.runtimeType),
        const EasyTreeNodeKey<Type>(MvcController),
        EasyTreeNodeKey<MvcController>(_controller),
        if (single) EasyTreeNodeKey<MvcSingleEasyTreeNodeKeyValue>(MvcSingleEasyTreeNodeKeyValue(TControllerType)),
      ];

  @override
  Widget buildChild() => _controller.view(this)._buildView(this);

  @override
  TControllerType get controller => _controller;

  @override
  TModelType get model => (widget as Mvc<TControllerType, TModelType>).model;

  @override
  BuildContext get buildContext => this;
}
