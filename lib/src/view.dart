part of './flutter_mvc.dart';

abstract class MvcView<TControllerType extends MvcController<TModelType>, TModelType> {
  Widget _buildView(MvcContext ctx) {
    if (ctx is MvcContext<TControllerType, TModelType>) return buildView(ctx);
    return buildView(MvcProxyContext<TControllerType, TModelType>(ctx));
  }

  Widget buildView(MvcContext<TControllerType, TModelType> ctx);
}

typedef MvcModelessView<TControllerType extends MvcController> = MvcView<TControllerType, void>;

class MvcViewBuilder<TControllerType extends MvcController<TModelType>, TModelType> extends MvcView<TControllerType, TModelType> {
  MvcViewBuilder(this.builder);
  final Widget Function(MvcContext<TControllerType, TModelType> ctx) builder;
  @override
  Widget buildView(MvcContext<TControllerType, TModelType> ctx) => builder(ctx);
}

typedef MvcModelessViewBuilder<TControllerType extends MvcController> = MvcViewBuilder<TControllerType, void>;
