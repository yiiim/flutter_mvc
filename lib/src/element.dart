part of './flutter_mvc.dart';

class MvcOwner extends EasyTreeRelationOwner {
  static final MvcOwner sharedOwner = MvcOwner();
  T? get<T extends MvcController>({BuildContext? context}) {
    if (context == null) return (easyTreeGetChildInAll(EasyTreeNodeKey<Type>(T)) as MvcElement?)?._controller as T?;
    var element = EasyTreeElement.getEasyTreeElementFromContext(context, easyTreeOwner: this);
    var controller = (element as MvcElement?)?._controller;
    if (controller is T) return controller;
    return controller?.parent<T>();
  }
}

class Mvc<TControllerType extends MvcController<TModelType>, TModelType> extends Widget {
  const Mvc({required this.creater, required this.model, Key? key}) : super(key: key);
  final TControllerType Function() creater;
  final TModelType model;
  static T? get<T extends MvcController>({BuildContext? context}) => MvcOwner.sharedOwner.get<T>(context: context);

  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this);
}

class MvcElement<TControllerType extends MvcController<TModelType>, TModelType> extends EasyTreeRelationElement implements MvcContext<TControllerType, TModelType> {
  MvcElement(super.widget)
      : _controller = (widget as Mvc<TControllerType, TModelType>).creater(),
        super(easyTreeOwner: MvcOwner.sharedOwner);

  final TControllerType _controller;

  @override
  void update(covariant Widget newWidget) {
    var oldWidget = widget;
    super.update(newWidget);
    if ((oldWidget as Mvc<TControllerType, TModelType>?)?.model != (newWidget as Mvc<TControllerType, TModelType>?)?.model) {
      _controller.updateState<TModelType>(updater: (state) => state?.value = (widget as Mvc<TControllerType, TModelType>).model);
    }
  }

  @override
  void mountEasyTree(EasyTreeNode? parent) {
    super.mountEasyTree(parent);
    _controller.addListener(markNeedsBuild);
    _controller.initState<TModelType>((widget as Mvc<TControllerType, TModelType>).model);
    _controller._initForElement(this);
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
  List<EasyTreeNodeKey> get keys => [EasyTreeNodeKey<Type>(_controller.runtimeType), const EasyTreeNodeKey<Type>(MvcController)];

  @override
  Widget buildChild() => _controller.view().buildView(this);

  @override
  TControllerType get controller => _controller;

  @override
  TModelType get model => (widget as Mvc<TControllerType, TModelType>).model;
}
