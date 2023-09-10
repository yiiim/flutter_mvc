import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

/// with the service get power for update [MvcServiceScope]
mixin MvcService on DependencyInjectionService {
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

/// You can update this Widget using the following methods：
/// ## update at controlle
/// ```dart
/// // in the MvcView
/// MvcServiceScope<TestService>(
///    builder: (context, service) {
///       return Text(service.title);
///    },
/// )
///
/// // in the MvcController, will be update all MvcServiceScope<TestService>
/// updateService<TestService>();
/// ```
/// ---
/// ## update at the service
///
/// ```dart
/// // anywhere
/// MvcServiceScope<TestService>(
///    builder: (context, service) {
///       return Text(service.title);
///    },
/// )
///
/// // in the TestService
/// class TestService with DependencyInjectionService, MvcService {
///   String title = "Test Title";
///   void changeTitle(String newTitle) {
///     title = newTitle;
///     // will be update all MvcServiceScope<TestService>
///     update();
///   }
/// }
/// ```
class MvcServiceScope<TServiceType extends Object> extends MvcStatefulWidget {
  const MvcServiceScope({required this.builder, super.id, super.classes, super.key});
  final Widget Function(MvcContext context, TServiceType) builder;
  Type get trueType => TServiceType;

  @override
  StatefulElement createElement() => _MvcStateScopeElement<TServiceType>(this);

  @override
  MvcWidgetState<MvcStatefulWidget<MvcController>, MvcController> createState() => _MvcStateScopeState<TServiceType>();
} 

class _MvcStateScopeElement<TServiceType extends Object> extends MvcStatefulElement {
  _MvcStateScopeElement(super.widget);

  @override
  MvcWidgetManager get manager => _MvcStateScopeManager<TServiceType>(this);
}

class _MvcStateScopeManager<TServiceType extends Object> extends MvcWidgetManager {
  _MvcStateScopeManager(super.element);

  @override
  bool isMatch(MvcWidgetQueryPredicate predicate) {
    if (predicate.serviceType != null) {
      if (predicate.serviceType == TServiceType) {
        return true;
      }
    }
    return super.isMatch(predicate);
  }
}

class _MvcStateScopeState<TServiceType extends Object> extends MvcWidgetState<MvcServiceScope<TServiceType>, MvcController> {
  late final _serviceState = controller.getService<TServiceType>();

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (_serviceState is MvcService) {
      (_serviceState as MvcService)._updateDelegate.add(_update);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_serviceState is MvcService) {
      (_serviceState as MvcService)._updateDelegate.remove(_update);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context as MvcContext, _serviceState);
  }
}
