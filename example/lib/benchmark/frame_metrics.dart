import 'dart:convert';
import 'dart:ui' show FramePhase;

import 'package:flutter/scheduler.dart';

/// Collects [FrameTiming] samples for the benchmark page.
///
/// Keeps a rolling window for the live HUD plus an explicit session buffer
/// that is exported as JSON after a recorded run.
class FrameMetrics {
  FrameMetrics({this.windowSize = 900});

  /// Rolling-window capacity (~7.5s at 120fps) used for live readouts.
  final int windowSize;

  final List<FrameTiming> _window = <FrameTiming>[];
  List<FrameTiming> _session = <FrameTiming>[];
  bool _recording = false;

  bool get recording => _recording;
  int get windowLength => _window.length;
  int get sessionLength => _session.length;

  /// Feed from `SchedulerBinding.addTimingsCallback`.
  void addTimings(List<FrameTiming> timings) {
    _window.addAll(timings);
    final overflow = _window.length - windowSize;
    if (overflow > 0) _window.removeRange(0, overflow);
    if (_recording) _session.addAll(timings);
  }

  void startSession() {
    _session = <FrameTiming>[];
    _recording = true;
  }

  /// Stops recording and returns the captured frames.
  List<FrameTiming> stopSession() {
    _recording = false;
    return _session;
  }

  static double _ms(Duration d) => d.inMicroseconds / 1000.0;

  /// Summary stats (ms) over [frames] for one phase (build/raster/total).
  static Map<String, double> phaseStats(
    List<FrameTiming> frames,
    Duration Function(FrameTiming) pick,
  ) {
    if (frames.isEmpty) return const <String, double>{};
    final values = frames.map((f) => _ms(pick(f))).toList()..sort();

    double pct(double q) {
      final i = (values.length - 1) * q;
      final lo = i.floor();
      final hi = i.ceil();
      final v = values[lo] + (values[hi] - values[lo]) * (i - lo);
      return double.parse(v.toStringAsFixed(3));
    }

    final avg = values.reduce((a, b) => a + b) / values.length;
    return <String, double>{
      'avg': double.parse(avg.toStringAsFixed(3)),
      'p50': pct(0.50),
      'p90': pct(0.90),
      'p99': pct(0.99),
      'max': double.parse(values.last.toStringAsFixed(3)),
    };
  }

  /// Percentile stats over the rolling window for the live display.
  Map<String, Map<String, double>> liveStats() => <String, Map<String, double>>{
    'build': phaseStats(_window, (f) => f.buildDuration),
    'raster': phaseStats(_window, (f) => f.rasterDuration),
    'total': phaseStats(_window, (f) => f.totalSpan),
  };

  /// Refresh rate inferred from the median interval between consecutive
  /// vsync starts — more reliable than `display.refreshRate`, which can
  /// report 0 (some simulators) or a nominal value that doesn't match the
  /// actually observed cadence.
  static double effectiveRefreshHz(List<FrameTiming> frames) {
    if (frames.length < 8) return 60.0;
    final intervals = <double>[
      for (var i = 1; i < frames.length; i++)
        (frames[i].timestampInMicroseconds(FramePhase.vsyncStart) -
                frames[i - 1].timestampInMicroseconds(FramePhase.vsyncStart)) /
            1000.0,
    ]..sort();
    final median = intervals[intervals.length ~/ 2];
    return median > 0 ? 1000.0 / median : 60.0;
  }

  /// Number of recorded frames whose build or raster phase missed its vsync
  /// slot. [FrameTiming.totalSpan] includes pipeline latency (build and raster
  /// run in different vsync intervals) and is not a jank signal.
  static int jankCount(List<FrameTiming> frames, double budgetMs) => frames
      .where(
        (f) =>
            _ms(f.buildDuration) > budgetMs || _ms(f.rasterDuration) > budgetMs,
      )
      .length;

  /// Serializes a finished session into a self-describing report.
  static Map<String, dynamic> buildReport({
    required List<FrameTiming> frames,
    required double refreshHz,
    required Map<String, Object?> context,
  }) {
    final budgetMs = 1000.0 / refreshHz;
    return <String, dynamic>{
      'schema': 'spoiler_benchmark/1',
      'generatedAt': DateTime.now().toIso8601String(),
      ...context,
      'frameCount': frames.length,
      'refreshHz': refreshHz,
      'budgetMs': double.parse(budgetMs.toStringAsFixed(2)),
      'jankFrames': jankCount(frames, budgetMs),
      'buildMs': phaseStats(frames, (f) => f.buildDuration),
      'rasterMs': phaseStats(frames, (f) => f.rasterDuration),
      'totalMs': phaseStats(frames, (f) => f.totalSpan),
    };
  }

  static String encodeReport(Map<String, dynamic> report) =>
      const JsonEncoder.withIndent('  ').convert(report);
}
