import 'package:flutter/material.dart';

import 'framework.dart';
import 'mvc.dart';

class MvcBuilder<TControllerType extends MvcController> extends MvcStatelessWidget<TControllerType> {
  const MvcBuilder({super.key, super.classes, super.id, required this.builder});
  final Widget Function(MvcContext<TControllerType> context) builder;
  @override
  Widget build(BuildContext context) {
    return builder(context as MvcContext<TControllerType>);
  }
}

class MvcHeader extends MvcBuilder {
  const MvcHeader({required super.builder, super.id, super.classes, super.key});
}

class MvcBody extends MvcBuilder {
  const MvcBody({required super.builder, super.id, super.classes, super.key});
}

class MvcFooter extends MvcBuilder {
  const MvcFooter({required super.builder, super.id, super.classes, super.key});
}
