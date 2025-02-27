import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

/// An extension of [SpoilerController] that adds animated "wave" effects to
/// the spoiler particles. This controller periodically schedules wave animations
/// that move particles within the bounds of the spoiler area.
class SpoilerSpotsController extends SpoilerController {
  /// Used for randomizing wave timings, random offsets, etc.
  final Random _random = Random();

  /// Periodically fires waves at a fixed interval (1 second).
  Timer? _periodicTimer;

  /// Stores timers that trigger individual waves with random delays.
  final List<Timer> _delayedTimers = [];

  /// A list of [AnimationController]s managing each active wave animation.
  /// We create a new controller per wave, and dispose it after the wave completes.
  final List<AnimationController> _activeWaveControllers = [];

  /// Tracks how many waves are currently animating. This is used to ensure we
  /// don't exceed the maximum allowed waves (as defined in [WidgetSpoilerConfiguration.maxActiveWaves]).
  int _activeWaves = 0;

  /// A reference to the [TickerProvider] for creating animation controllers.
  final TickerProvider _vsync;

  /// Stores the spoiler configuration to know max waves, fade options, etc.
  late WidgetSpoilerConfiguration _configuration;

  /// Creates a new [SpoilerSpotsController].
  ///
  /// [vsync] is required for animations.
  SpoilerSpotsController({
    required TickerProvider vsync,
  })  : _vsync = vsync,
        super(vsync: vsync);

  /// Initializes the particle system based on the given [rect] and [configuration].
  /// Also starts a periodic timer that triggers wave scheduling every second.
  ///
  /// This is usually called once you have the final spoiler bounds (size).
  void initParticles(Rect rect, WidgetSpoilerConfiguration configuration) {
    _configuration = configuration;
    // Initializes the particle field from the base SpoilerController method:
    initializeParticles(Path()..addRect(rect), configuration);

    // Periodically schedule wave animations. Each tick schedules 3 waves
    // with random delays. (E.g. 3 random bursts every 1 second.)
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _scheduleWaveAnimation();
      _scheduleWaveAnimation();
      _scheduleWaveAnimation();
    });
  }

  /// Creates a random delay (up to 3s) before starting a single wave animation.
  /// The timer is tracked in [_delayedTimers], and removed once it fires.
  void _scheduleWaveAnimation() {
    final delay = Duration(milliseconds: _random.nextInt(3000));
    Timer? t;

    t = Timer(delay, () {
      _startWaveAnimation();
      _delayedTimers.remove(t);
    });
    _delayedTimers.add(t);
  }

  /// Overrides the default toggle behavior to ensure we do not toggle while
  /// a fade animation is already in progress.
  ///
  /// - If the spoiler is enabled, re-initialize the particles (which also
  ///   restarts the wave scheduling).
  /// - If disabled, dispose all wave timers and controllers.
  @override
  void toggle([Offset? fadeOffset]) {
    // Prevent toggling while a fade is in progress
    if (isFading) return;

    super.toggle(fadeOffset);

    if (isEnabled) {
      initParticles(spoilerBounds, _configuration);
    } else {
      _disposeTimersAndControllers();
    }
  }

  /// Starts a new wave animation if we haven't reached the max number of
  /// concurrent waves. Each wave:
  /// 1. Picks a random origin inside [spoilerBounds].
  /// 2. Creates an [AnimationController] and a [CurvedAnimation].
  /// 3. For each particle within the chosen radius, computes a new offset
  ///    and animates that particle's position to the new offset.
  /// 4. When the animation completes, it disposes the controller and decrements
  ///    the active wave count.
  void _startWaveAnimation() {
    // If disabled or the spoiler area is zero, skip.
    if (!isEnabled || spoilerBounds == Rect.zero) return;

    // Don't exceed the max wave count from the config.
    if (_activeWaves >= _configuration.maxActiveWaves) return;
    _activeWaves++;

    // Random wave origin and radius
    final offset = spoilerBounds.randomOffset();
    final maxRadius = spoilerBounds.shortestSide ~/ 4;
    if (maxRadius == 0) return;
    final awayRadius = _random.nextInt(maxRadius);

    // Create the wave animation controller
    final animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: _vsync,
    );

    _activeWaveControllers.add(animationController);

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    // For each particle, if it's within the 'wave radius', compute a new
    // target position and animate it.
    const margin = 10.0;

    for (int index = 0; index < particles.length; index++) {
      final current = particles[index];
      final distanceDiff = offset - current;
      final distanceDelta = distanceDiff.distance;

      // If it's outside the wave's radius, skip.
      if (distanceDelta >= awayRadius) continue;

      // The direction from the wave origin to this particle.
      final direction = distanceDiff / distanceDelta;

      // The initial "endpoint," moving the particle away from the wave origin.
      var possibleEndPoint = current.translate(
        -(awayRadius - distanceDelta) * direction.dx,
        -(awayRadius - distanceDelta) * direction.dy,
      );

      // If the endpoint is outside the spoiler bounds, use a random valid point instead.
      if (!spoilerBounds.containsOffset(possibleEndPoint)) {
        possibleEndPoint = Offset(
          spoilerBounds.left + margin + _random.nextDouble() * (spoilerBounds.width - 2 * margin),
          spoilerBounds.top + margin + _random.nextDouble() * (spoilerBounds.height - 2 * margin),
        );
      }

      // Add additional randomness around that possible endpoint.
      final randomAngle = _random.nextDouble() * 2 * pi;
      final additionalOffset = margin + _random.nextDouble() * margin;
      final randomEndPoint = possibleEndPoint.translate(
        additionalOffset * cos(randomAngle),
        additionalOffset * sin(randomAngle),
      );

      // If the random endpoint is inside bounds, use it; otherwise revert to `possibleEndPoint`.
      final finalEndpoint = spoilerBounds.containsOffset(randomEndPoint) ? randomEndPoint : possibleEndPoint;

      // A two-phase animation: move from [current] → [possibleEndPoint], then [possibleEndPoint] → [finalEndpoint].
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

      // As the animation progresses, update this particle's position.
      void waveAnimationListener() {
        // If we've turned off the spoiler, or there's no particle left, skip.
        if (!isEnabled || particles.isEmpty) return;
        particles[index] = current.copyWith(dx: anim.value.dx, dy: anim.value.dy);
      }

      anim.addListener(waveAnimationListener);
    }

    // Begin the wave animation. Clean up on completion.
    animationController.forward().whenComplete(() {
      animationController.dispose();
      _activeWaveControllers.remove(animationController);
      _activeWaves--;
    });
  }

  /// Cancels the periodic wave timer, cancels all delayed wave timers, and
  /// disposes any active wave animations. This typically happens when the
  /// spoiler is disabled.
  void _disposeTimersAndControllers() {
    // Cancel the periodic "wave scheduling" timer.
    _periodicTimer?.cancel();

    // Cancel all delayed wave timers.
    for (final timer in _delayedTimers) {
      timer.cancel();
    }
    _delayedTimers.clear();

    // Dispose any currently running wave animations.
    for (final controller in _activeWaveControllers) {
      controller.dispose();
    }
    _activeWaveControllers.clear();
  }

  @override
  void dispose() {
    // Clean up local timers/controllers in addition to the base disposal.
    _disposeTimersAndControllers();
    super.dispose();
  }
}
