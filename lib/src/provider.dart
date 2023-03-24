part of 'flutter_mvc.dart';

class _MvcScopedProviderController extends MvcProxyController implements MvcControllerScopedBuilder, MvcServiceScopedBuilder {
  _MvcScopedProviderController(this.provider);
  final void Function(MvcControllerCollection collection)? provider;
  @override
  void mvcControllerScopedBuild(MvcControllerCollection collection) {
    provider?.call(collection);
  }

  @override
  void serviceScopedBuild(ServiceCollection collection) {}
}

class MvcScopedProvider extends StatelessWidget {
  const MvcScopedProvider({required this.child, required this.provider, super.key});
  final void Function(MvcControllerCollection collection)? provider;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MvcProxy(
      proxyCreate: () => _MvcScopedProviderController(provider),
      child: child,
    );
  }
}
