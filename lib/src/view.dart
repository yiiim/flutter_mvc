part of './flutter_mvc.dart';

abstract class MvcView<TControllerType extends MvcController<TModelType>, TModelType> {
  Widget buildView(MvcContext<TControllerType, TModelType> ctx);
}
