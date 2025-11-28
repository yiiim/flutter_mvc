import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ticker Provider Mixins', () {
    testWidgets('MvcSingleTickerProviderStateMixin provides ticker', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MaterialApp(
            home: Mvc<_SingleTickerController, void>(
              create: _SingleTickerController.new,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final controller = context.getService<_SingleTickerController>();

      // Controller can create animation controller
      final animController = AnimationController(
        vsync: controller,
        duration: const Duration(seconds: 1),
      );

      expect(animController, isNotNull);
      expect(animController.duration, equals(const Duration(seconds: 1)));

      animController.dispose();
    });

    testWidgets('MvcTickerProviderStateMixin provides multiple tickers', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MaterialApp(
            home: Mvc<_MultiTickerController, void>(
              create: _MultiTickerController.new,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final controller = context.getService<_MultiTickerController>();

      // Controller can create multiple animation controllers
      final animController1 = AnimationController(
        vsync: controller,
        duration: const Duration(milliseconds: 500),
      );

      final animController2 = AnimationController(
        vsync: controller,
        duration: const Duration(milliseconds: 300),
      );

      expect(animController1, isNotNull);
      expect(animController2, isNotNull);
      expect(animController1, isNot(same(animController2)));

      animController1.dispose();
      animController2.dispose();
    });

    testWidgets('ticker provider works with animations', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MaterialApp(
            home: Mvc<_AnimationTestController, void>(
              create: _AnimationTestController.new,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Animation: 0.0'), findsOneWidget);

      final context = tester.element(find.byType(Scaffold));
      final controller = context.getService<_AnimationTestController>();

      // Start animation
      controller.startAnimation();

      // Pump one frame to start animation
      await tester.pump();
      // Pump animation to midpoint
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should be at or past midpoint
      expect(controller.animationValue >= 0.4, isTrue, reason: 'Animation value: ${controller.animationValue}');
      expect(controller.animationValue <= 0.6, isTrue, reason: 'Animation value: ${controller.animationValue}');
    });
  });
}

// Test Controllers - these need to be classes for mixin functionality
class _SingleTickerController extends MvcController<void> with MvcSingleTickerProviderStateMixin {
  @override
  MvcView view() {
    return MvcViewBuilder<_SingleTickerController>(
      (controller) => const Scaffold(
        body: Text('Empty'),
      ),
    );
  }
}

class _MultiTickerController extends MvcController<void> with MvcTickerProviderStateMixin {
  @override
  MvcView view() {
    return MvcViewBuilder<_MultiTickerController>(
      (controller) => const Scaffold(
        body: Text('Empty'),
      ),
    );
  }
}

class _AnimationTestController extends MvcController<void> with MvcSingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;

  double get animationValue => _animation.value;

  @override
  void init() {
    super.init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animController);
  }

  void startAnimation() {
    _animController.forward();
  }

  @override
  MvcView view() {
    return MvcViewBuilder<_AnimationTestController>(
      (controller) => Scaffold(
        body: AnimatedBuilder(
          animation: controller._animation,
          builder: (context, child) {
            return Text('Animation: ${controller.animationValue}');
          },
        ),
      ),
    );
  }

  @override
  void deactivate() {
    _animController.dispose();
    super.deactivate();
  }
}
