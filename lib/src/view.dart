part of './flutter_mvc.dart';

abstract class MvcView<TControllerType extends MvcController<TModelType>, TModelType> with DependencyInjectionService {
  late final TControllerType controller = getService<MvcController>() as TControllerType;
  TModelType get model => controller.model;
  BuildContext get context => controller.context;

  Widget buildView();
}

typedef MvcModelessView<TControllerType extends MvcController> = MvcView<TControllerType, void>;

class MvcViewBuilder<TControllerType extends MvcController<TModelType>, TModelType> extends MvcView<TControllerType, TModelType> {
  MvcViewBuilder(this.builder);
  final Widget Function(TControllerType controller) builder;
  @override
  Widget buildView() => builder(controller);
}

typedef MvcModelessViewBuilder<TControllerType extends MvcController> = MvcViewBuilder<TControllerType, void>;
