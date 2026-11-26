import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/spoiler_drawing_strategy.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';

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
  final Random _random = Random(ParticleSpoilerDrawer.debugRandomSeed);

  /// Fires every second, triggering multiple wave schedules.
  Timer? _periodicWaveTimer;

  /// Keeps track of short-lived delayed timers for each wave.
  /// (We spawn 3 random delays each second, each triggers a wave.)
  final List<Timer> _delayedWaveTimers = [];

  /// Active waves with their associated animation controller and affected particle states.
  /// [_activeWaves.length] is the running-wave count used to enforce
  /// [WidgetSpoilerConfig.maxActiveWaves].
  final List<_ActiveWave> _activeWaves = [];

  /// Holds wave-related config (maxActiveWaves, fade options, etc.).
  WidgetSpoilerConfig _config = WidgetSpoilerConfig.defaultConfig();

  /// Creates a new wave-enabled spoiler controller.
  ///
  /// [vsync] is required so we can animate wave expansions.
  SpoilerSpotsController({required super.vsync});

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Sets up the spoiler’s particles via [initializeParticles] in the parent,
  /// then starts a periodic timer that spawns wave animations every second.
  ///
  /// [path] defines the spoiler area.
  /// [configuration] includes fields like [WidgetSpoilerConfig.maxActiveWaves], which limit concurrency.
  /// [rects] optionally provide per-line bounds.
  @override
  void initializeParticles(
    Path path,
    SpoilerConfig configuration, {
    List<Rect>? rects,
  }) {
    if (configuration is WidgetSpoilerConfig) {
      _config = configuration;
    }

    // Call the base spoiler initialization (particles, fade, etc.).
    super.initializeParticles(path, configuration, rects: rects);

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

  /// Spawns one wave animation if we're under [WidgetSpoilerConfig.maxActiveWaves].
  ///
  /// **Wave steps**:
  ///  1. Pick a random origin, radius.
  ///  2. Animate each particle within radius to a new offset.
  ///  3. Dispose wave’s [AnimationController] when done.
  void _launchWaveAnimation() {
    // If the spoiler is disabled or the bounding area is empty, skip.
    if (!isEnabled || spoilerBounds == Rect.zero) return;

    // Enforce max wave concurrency.
    if (_activeWaves.length >= _config.maxActiveWaves) return;

    // Determine wave radius
    final maxRadius = spoilerBounds.shortestSide ~/ 4;
    if (maxRadius == 0) {
      return;
    }
    final waveRadius = _random.nextInt(maxRadius).toDouble();

    // Pick a random wave origin
    final waveOrigin = spoilerBounds.randomOffset(_random);

    final Map<int, _WaveParticleBinding> affected = {};
    const margin = 10.0;

    for (int i = 0; i < particles.length; i++) {
      final current = particles[i];
      final distVec = waveOrigin - current;
      final dist = distVec.distance;

      // If beyond waveRadius, skip
      if (dist >= waveRadius) continue;

      // Remove this particle from any other active wave's affected list to resolve animation conflicts.
      _removeParticleFromOtherWaves(current.id);

      // Move the particle outward from wave origin.
      final direction = distVec / (dist > 0.0 ? dist : 1.0);

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
      final finalOffset = current.path.contains(randomOffset)
          ? randomOffset
          : waveEndpoint;

      affected[current.id] = _WaveParticleBinding(
        index: i,
        state: _ParticleWaveState(
          start: current,
          mid: waveEndpoint,
          end: finalOffset,
        ),
      );
    }

    // If no particles are affected, we don't need to run a wave animation.
    if (affected.isEmpty) {
      return;
    }

    // Create a dedicated controller for this wave
    final waveCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: tickerProvider,
    );
    final activeWave = _ActiveWave(
      controller: waveCtrl,
      affectedParticles: affected,
    );
    _activeWaves.add(activeWave);

    final anim = CurvedAnimation(
      parent: waveCtrl,
      curve: Curves.easeInOutCubic,
    );

    // Update affected particles' positions in a single listener.
    // Only bound particles are touched — O(affected) per wave per frame
    // instead of O(total particles). The id check guards against the
    // particle list being rebuilt mid-wave (re-init).
    anim.addListener(() {
      if (!isEnabled || particles.isEmpty) return;

      for (final entry in activeWave.affectedParticles.entries) {
        final binding = entry.value;
        final index = binding.index;
        if (index >= particles.length || particles[index].id != entry.key) {
          continue;
        }
        final nextPos = binding.state.getPositionAt(anim.value);
        particles[index] = particles[index].copyWith(
          dx: nextPos.dx,
          dy: nextPos.dy,
        );
      }
    });

    // Start the wave, and when it's complete, clean up
    waveCtrl.forward().whenComplete(() {
      waveCtrl.dispose();
      _activeWaves.remove(activeWave);
    });
  }

  void _removeParticleFromOtherWaves(int particleId) {
    for (final wave in _activeWaves) {
      wave.affectedParticles.remove(particleId);
    }
  }

  /// Returns the number of currently active wave animations.
  int get activeWavesCount => _activeWaves.length;

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
    return true;
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
    for (final wave in _activeWaves) {
      wave.controller.dispose();
    }
    _activeWaves.clear();
  }

  @override
  void dispose() {
    // Clean up wave timers and controllers in addition to the base disposal
    _cancelAllWaveActivities();
    super.dispose();
  }
}

class _ParticleWaveState {
  final Offset start;
  final Offset mid;
  final Offset end;

  _ParticleWaveState({
    required this.start,
    required this.mid,
    required this.end,
  });

  Offset getPositionAt(double t) {
    if (t < 0.5) {
      return Offset.lerp(start, mid, t * 2.0)!;
    }
    return Offset.lerp(mid, end, (t - 0.5) * 2.0)!;
  }
}

class _WaveParticleBinding {
  /// Index into the controller's particle list, captured at wave launch.
  final int index;
  final _ParticleWaveState state;

  const _WaveParticleBinding({required this.index, required this.state});
}

class _ActiveWave {
  final AnimationController controller;

  /// Particle id -> binding. Entries may be removed mid-flight when a
  /// newer wave claims the same particle.
  final Map<int, _WaveParticleBinding> affectedParticles;

  _ActiveWave({required this.controller, required this.affectedParticles});
}
