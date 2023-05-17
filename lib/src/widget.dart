part of './flutter_mvc.dart';

abstract class MvcWidget extends Widget {
  const MvcWidget({super.key});
}

abstract class MvcStatefulWidget<TControllerType extends MvcController> extends StatefulWidget implements MvcWidget {
  const MvcStatefulWidget({super.key});

  @override
  StatefulElement createElement() => MvcStatefulElement(this);

  @override
  MvcWidgetState createState();
}

abstract class MvcWidgetState<TControllerType extends MvcController, T extends MvcStatefulWidget<TControllerType>> extends State<T> with DependencyInjectionService {
  MvcStatefulElement<TControllerType>? _element;
  TControllerType get controller => _element!._controller!;

  void initMvc() {}
}
