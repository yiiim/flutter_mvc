part of './flutter_mvc.dart';

class MvcApp extends StatelessWidget {
  const MvcApp(
    this.child, {
    this.parentServiceProvider,
    super.key,
  });

  final Widget child;
  final ServiceProvider? parentServiceProvider;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
