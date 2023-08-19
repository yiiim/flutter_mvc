import 'package:dart_dependency_injection/dart_dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

abstract class MvcServiceState with DependencyInjectionService {
  late final List<void Function()> _updateDelegate = [];
  void update() {
    for (var element in _updateDelegate) {
      element();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _updateDelegate.clear();
  }
}

class MvcServiceStateScope<TStateType extends MvcServiceState> extends MvcStatefulWidget {
  const MvcServiceStateScope({required this.builder, super.id, super.classes, super.key});
  final Widget Function(MvcContext context, TStateType) builder;
  @override
  MvcWidgetState<MvcStatefulWidget<MvcController>, MvcController> createState() => _MvcStateScopeState<TStateType>();
}

class _MvcStateScopeState<TStateType extends MvcServiceState> extends MvcWidgetState<MvcServiceStateScope<TStateType>, MvcController> {
  late final _serviceState = controller.getService<TStateType>();

  void _update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    assert(TStateType != MvcServiceState, 'TStateType must be provide');
    _serviceState._updateDelegate.add(_update);
  }

  @override
  void dispose() {
    super.dispose();
    _serviceState._updateDelegate.remove(_update);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context as MvcContext, _serviceState);
  }
}