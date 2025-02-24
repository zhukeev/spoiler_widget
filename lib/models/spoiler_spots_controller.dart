import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';

class SpoilerSpotsController extends SpoilerController {
  final Random _random = Random();
  Timer? periodicTimer;
  final List<Timer> _delayedTimers = [];
  // Track active AnimationControllers.
  final List<AnimationController> _activeWaveControllers = [];

  final int maxActiveWaves;
  int _activeWaves = 0;

  SpoilerSpotsController({
    required super.particleColor,
    required super.maxParticleSize,
    required super.fadeRadiusDeflate,
    required super.speedOfParticles,
    required super.particleDensity,
    required super.fadeAnimationEnabled,
    required super.enableGesture,
    required super.vsync,
    this.maxActiveWaves = 3,
    super.initiallyEnabled = false,
  });

  void initParticles(Rect rect) {
    initializeParticles([rect]);
    periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _scheduleWaveAnimation();
      _scheduleWaveAnimation();
      _scheduleWaveAnimation();
    });
  }

  void _scheduleWaveAnimation() {
    final delay = Duration(milliseconds: _random.nextInt(3000));
    Timer? t;
    t = Timer(delay, () {
      _startWaveAnimation();
      _delayedTimers.remove(t);
    });
    _delayedTimers.add(t);
  }

  @override
  void toggle([Offset? fadeOffset]) {
    super.toggle(fadeOffset);

    debugPrint('toggle isEnabled $isEnabled');

    if (isEnabled) {
      initParticles(spoilerBounds);
    } else {
      debugPrint('toggle $spoilerBounds');
      _disposeTimersAndControllers();
    }
  }

  void _startWaveAnimation() {
    if (!isEnabled || spoilerBounds == Rect.zero) return;
    if (_activeWaves >= maxActiveWaves) return;
    _activeWaves++;

    // Choose a random origin for the wave.
    final offset = spoilerBounds.randomOffset();
    final maxRadius = spoilerBounds.shortestSide ~/ 4;
    if (maxRadius == 0) return;
    final awayRadius = _random.nextInt(maxRadius);

    // Create a new AnimationController for this wave.
    final animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    );
    // Add the controller to our tracking list.
    _activeWaveControllers.add(animationController);

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    // Animate every particle within the wave's reach.
    for (int index = 0; index < particles.length; index++) {
      final current = particles[index];
      final distanceDiff = offset - current;
      final distanceDelta = distanceDiff.distance;
      if (distanceDelta >= awayRadius) continue;

      final direction = distanceDiff / distanceDelta;
      // Compute a preliminary endpoint.
      var possibleEndPoint = current.translate(
        -(awayRadius - distanceDelta) * direction.dx,
        -(awayRadius - distanceDelta) * direction.dy,
      );

      // If endpoint is outside or too close to the bounds, choose a random interior point.
      if (!spoilerBounds.containsOffset(possibleEndPoint) ||
          (possibleEndPoint.dx <= spoilerBounds.left || possibleEndPoint.dx >= spoilerBounds.right) ||
          (possibleEndPoint.dy <= spoilerBounds.top || possibleEndPoint.dy >= spoilerBounds.bottom)) {
        const margin = 20.0;
        possibleEndPoint = Offset(
          spoilerBounds.left + margin + _random.nextDouble() * (spoilerBounds.width - 2 * margin),
          spoilerBounds.top + margin + _random.nextDouble() * (spoilerBounds.height - 2 * margin),
        );
      }

      // Add extra randomness.
      final randomAngle = _random.nextDouble() * 2 * pi;
      final additionalOffset = 10.0 + _random.nextDouble() * 10;
      final randomEndPoint = possibleEndPoint.translate(
        additionalOffset * cos(randomAngle),
        additionalOffset * sin(randomAngle),
      );
      final finalEndpoint = spoilerBounds.containsOffset(randomEndPoint)
          ? randomEndPoint
          : Offset(
              spoilerBounds.left + 20.0 + _random.nextDouble() * (spoilerBounds.width - 40.0),
              spoilerBounds.top + 20.0 + _random.nextDouble() * (spoilerBounds.height - 40.0),
            );

      // Create a two-phase tween.
      final anim = TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween(begin: current, end: possibleEndPoint),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: possibleEndPoint, end: finalEndpoint),
          weight: 50,
        ),
      ]).animate(curvedAnimation);

      // Listener to update the particle's position.
      void waveAnimationListener() {
        if (!isEnabled || particles.isEmpty) return;
        particles[index] = current.copyWith(dx: anim.value.dx, dy: anim.value.dy);
      }

      anim.addListener(waveAnimationListener);
    }

    // Start the animation and clean up when complete.
    animationController.forward().whenComplete(() {
      animationController.dispose();
      _activeWaveControllers.remove(animationController);
      _activeWaves--;
    });
  }

  void _disposeTimersAndControllers() {
    // Cancel timers.
    periodicTimer?.cancel();
    for (final timer in _delayedTimers) {
      timer.cancel();
    }
    _delayedTimers.clear();

    // Dispose any active animation controllers.
    for (final controller in _activeWaveControllers) {
      controller.dispose();
    }
    _activeWaveControllers.clear();
  }

  @override
  void dispose() {
    _disposeTimersAndControllers();
    super.dispose();
  }
}
