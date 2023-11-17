import 'package:flutter/material.dart';

import 'framework.dart';
import 'mvc.dart';

/// Mvc framework context
///
/// This is the [MvcWidget]'s context, can be get in [MvcStatelessWidget.build] method or [MvcWidgetState.context].
abstract class MvcContext<TControllerType extends MvcController> extends BuildContext {
  /// The nearest [Mvc]'s controller in this context if of type [TControllerType]
  TControllerType get controller;

  /// Depend on a service, if the service is not exist, will throw an exception.
  ///
  /// If the service is [MvcService],this context will be update when the service call [MvcService.update].
  ///
  /// Alse will be update when the nearest [Mvc] call [MvcController.updateService<T>].
  ///
  /// See [dart_dependency_injection](https://github.com/yiiim/dart_dependency_injection) about how to inject service.
  T dependOnService<T extends Object>();

  /// Try depend on a service, if the service is not exist, will return null.
  /// Same as [dependOnService] but not throw an exception when the service is not exist.
  T? tryDependOnService<T extends Object>();
}

extension MvcContextExtension on BuildContext {
  T getService<T extends Object>() {
    return InheritedServiceProvider.of(this)!.get<T>();
  }

  T? tryGetService<T extends Object>() {
    return InheritedServiceProvider.of(this)?.tryGet<T>();
  }
}
