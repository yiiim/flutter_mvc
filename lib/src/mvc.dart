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
  const Mvc({required this.creater, TModelType? model, Key? key})
      : model = model ?? model as TModelType,
        super(key: key);
  final TControllerType Function() creater;
  final TModelType model;
  static T? get<T extends MvcController>({BuildContext? context}) => MvcOwner.sharedOwner.get<T>(context: context);

  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, creater());
}

class MvcSingle<TControllerType extends MvcController<TModelType>, TModelType> extends Mvc<TControllerType, TModelType> {
  const MvcSingle({required super.creater, super.model, super.key});
  @override
  Element createElement() => MvcElement<TControllerType, TModelType>(this, Mvc.get<TControllerType>() ?? creater());
}
