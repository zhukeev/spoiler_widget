import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

/// A specialized [SpoilerController] that adds "wave" animations to the spoiler particles.
///
/// This controller periodically spawns waves from random points within the spoiler bounds.
/// Each wave can animate any particles within its radius, giving a dynamic,
/// expanding “ripple” effect. For each wave:
///  1. A random origin inside [spoilerBounds] is selected.
///  2. Particles within a chosen radius move outward or to random offsets.
///  3. When the wave animation completes, it disposes its own [AnimationController].
///
/// The frequency and concurrency of waves is governed by:
///  - A periodic timer firing every second (by default).
///  - Randomized delayed timers for each wave (up to 3 per second).
///  - [WidgetSpoilerConfig.maxActiveWaves] limiting simultaneous waves.
class SpoilerSpotsController extends SpoilerController {
  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Random generator for wave timings, offsets, radii, etc.
  final Random _random = Random();

  /// Fires every second, triggering multiple wave schedules.
  Timer? _periodicWaveTimer;

  /// Keeps track of short-lived delayed timers for each wave.
  /// (We spawn 3 random delays each second, each triggers a wave.)
  final List<Timer> _delayedWaveTimers = [];

  /// One [AnimationController] per active wave, disposed upon wave completion.
  final List<AnimationController> _activeWaveControllers = [];

  /// Count of waves currently animating. Used to avoid exceeding [maxActiveWaves].
  int _runningWavesCount = 0;

  /// [TickerProvider] for creating wave animation controllers.
  final TickerProvider _vsync;

  /// Holds wave-related config (maxActiveWaves, fade options, etc.).
  WidgetSpoilerConfig _config = WidgetSpoilerConfig.defaultConfig();

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates a new wave-enabled spoiler controller.
  ///
  /// [vsync] is required so we can animate wave expansions.
  SpoilerSpotsController({
    required TickerProvider vsync,
  })  : _vsync = vsync,
        super(vsync: vsync);

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Sets up the spoiler’s particles via [initializeParticles] in the parent,
  /// then starts a periodic timer that spawns wave animations every second.
  ///
  /// [rect] is the bounding area.
  /// [configuration] includes fields like [maxActiveWaves], which limit concurrency.
  void initParticles(Rect rect, WidgetSpoilerConfig configuration) {
    _config = configuration;

    // Call the base spoiler initialization (particles, fade, etc.).
    initializeParticles(Path()..addRect(rect), configuration);

    // Cancel any existing timer to avoid duplicates.
    _periodicWaveTimer?.cancel();

    // Every second, schedule three waves with random delays.
    _periodicWaveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Attempt to schedule 3 waves in quick succession:
      for (int i = 0; i < 3; i++) {
        _scheduleRandomWave();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Wave Scheduling
  // ---------------------------------------------------------------------------

  /// Schedules a single wave after a random delay (up to 3 seconds).
  ///
  /// We store the Timer in [_delayedWaveTimers], then remove it once it fires.
  void _scheduleRandomWave() {
    if (!isEnabled) return; // skip if spoiler is disabled

    final delay = Duration(milliseconds: _random.nextInt(3000));
    late Timer waveTimer;

    waveTimer = Timer(delay, () {
      _delayedWaveTimers.remove(waveTimer);
      _launchWaveAnimation();
    });

    _delayedWaveTimers.add(waveTimer);
  }

  /// Spawns one wave animation if we're under [maxActiveWaves].
  ///
  /// **Wave steps**:
  ///  1. Pick a random origin, radius.
  ///  2. Animate each particle within radius to a new offset.
  ///  3. Dispose wave’s [AnimationController] when done.
  void _launchWaveAnimation() {
    // If the spoiler is disabled or the bounding area is empty, skip.
    if (!isEnabled || spoilerBounds == Rect.zero) return;

    // Enforce max wave concurrency.
    if (_runningWavesCount >= _config.maxActiveWaves) return;
    _runningWavesCount++;

    // Determine wave radius
    final maxRadius = spoilerBounds.shortestSide ~/ 4;
    if (maxRadius == 0) return;
    final waveRadius = _random.nextInt(maxRadius);

    // Pick a random wave origin
    final waveOrigin = spoilerBounds.randomOffset();

    // Create a dedicated controller for this wave
    final waveCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: _vsync,
    );
    _activeWaveControllers.add(waveCtrl);

    final anim = CurvedAnimation(
      parent: waveCtrl,
      curve: Curves.easeInOutCubic,
    );

    // Animate each particle within waveRadius
    const margin = 10.0;
    for (int i = 0; i < particles.length; i++) {
      final current = particles[i];
      final distVec = waveOrigin - current;
      final dist = distVec.distance;

      // If beyond waveRadius, skip
      if (dist >= waveRadius) continue;

      // Move the particle outward from wave origin.
      final direction = distVec / dist;

      final adjustedEnd = current.translate(
        -(waveRadius - dist) * direction.dx,
        -(waveRadius - dist) * direction.dy,
      );

      // If out of bounds, pick a random valid point
      var waveEndpoint = adjustedEnd;
      if (!spoilerBounds.containsOffset(waveEndpoint)) {
        waveEndpoint = Offset(
          spoilerBounds.left +
              margin +
              _random.nextDouble() * (spoilerBounds.width - 2 * margin),
          spoilerBounds.top +
              margin +
              _random.nextDouble() * (spoilerBounds.height - 2 * margin),
        );
      }

      // Add some random “wiggle” around waveEndpoint
      final randAngle = _random.nextDouble() * 2 * pi;
      final extraDist = margin + _random.nextDouble() * margin;
      final randomOffset = waveEndpoint.translate(
        extraDist * cos(randAngle),
        extraDist * sin(randAngle),
      );

      // If that offset is inside, use it; otherwise revert to waveEndpoint.
      final finalOffset =
          current.path.contains(randomOffset) ? randomOffset : waveEndpoint;

      // Build a two-phase tween: (current -> waveEndpoint -> finalOffset)
      final offsetTween = TweenSequence<Offset>([
        TweenSequenceItem(
          tween: Tween(begin: current, end: waveEndpoint),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: waveEndpoint, end: finalOffset),
          weight: 50,
        ),
      ]).animate(anim);

      // Update the particle's position on each frame
      offsetTween.addListener(() {
        if (!isEnabled || particles.isEmpty || i >= particles.length) return;
        // Because i might be out of range if particles changed, be mindful in real code
        particles[i] = current.copyWith(
          dx: offsetTween.value.dx,
          dy: offsetTween.value.dy,
        );
      });
    }

    // Start the wave, and when it's complete, clean up
    waveCtrl.forward().whenComplete(() {
      waveCtrl.dispose();
      _activeWaveControllers.remove(waveCtrl);
      _runningWavesCount--;
    });
  }

  // ---------------------------------------------------------------------------
  // Override: Toggle Behavior
  // ---------------------------------------------------------------------------

  /// Extends [toggle] to ensure we don't toggle mid-fade, and re-initialize
  /// wave scheduling if we just enabled.
  @override
  bool toggle(Offset fadeOffset) {
    final result = super.toggle(fadeOffset);

    if (!result) return false;

    // If we ended up enabled, re-init wave scheduling
    // (which also restarts wave timers).
    if (isEnabled) {
      updateConfiguration(_config.copyWith(isEnabled: true));
    } else {
      _cancelAllWaveActivities();
    }
    return isEnabled;
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Cancels the periodic wave timer, any delayed wave timers,
  /// and all active wave animations. Called when spoiler is disabled
  /// or during disposal.
  void _cancelAllWaveActivities() {
    // Stop the periodic wave scheduling
    _periodicWaveTimer?.cancel();
    _periodicWaveTimer = null;

    // Cancel all delayed wave triggers
    for (final t in _delayedWaveTimers) {
      t.cancel();
    }
    _delayedWaveTimers.clear();

    // Dispose any in-progress wave animations
    for (final ctrl in _activeWaveControllers) {
      ctrl.dispose();
    }
    _activeWaveControllers.clear();

    _runningWavesCount = 0;
  }

  @override
  void dispose() {
    // Clean up wave timers and controllers in addition to the base disposal
    _cancelAllWaveActivities();
    super.dispose();
  }
}
