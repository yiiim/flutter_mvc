part of 'flutter_mvc.dart';

abstract class MvcControllerProvider<T extends MvcController> {
  T create();
}
