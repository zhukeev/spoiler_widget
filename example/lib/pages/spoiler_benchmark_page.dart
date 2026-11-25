import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/spoiler_spots_controller.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';
import 'package:spoiler_widget/spoiler_overlay_widget.dart';

class SpoilerBenchmarkPage extends StatefulWidget {
  const SpoilerBenchmarkPage({super.key});

  @override
  State<SpoilerBenchmarkPage> createState() => _SpoilerBenchmarkPageState();
}

class _SpoilerBenchmarkPageState extends State<SpoilerBenchmarkPage>
    with TickerProviderStateMixin {
  late SpoilerSpotsController _controller;
  late Ticker _fpsTicker;

  // Configuration settings
  double _density = 0.3;
  double _speed = 0.5;
  double _maxParticleSize = 2.0;
  final bool _enableWaves = true;
  final int _maxActiveWaves = 15; // Set high for stress-testing

  // FPS Counter
  double _fps = 0.0;
  int _frameCount = 0;
  DateTime _lastFpsTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = SpoilerSpotsController(vsync: this);
    _initializeController();

    // Start FPS counter ticker
    _fpsTicker = createTicker((_) {
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastFpsTime).inMilliseconds;
      if (elapsed >= 500) {
        setState(() {
          _fps = (_frameCount * 1000) / elapsed;
          _frameCount = 0;
          _lastFpsTime = now;
        });
      }
    })..start();
  }

  void _initializeController() {
    final config = WidgetSpoilerConfig(
      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      maxActiveWaves: _maxActiveWaves,
      isEnabled: true,
      enableGestureReveal: false,
      particleConfig: ParticleConfig(
        density: _density,
        speed: _speed,
        color: Colors.cyanAccent,
        maxParticleSize: _maxParticleSize,
        enableWaves: _enableWaves,
        maxWaveRadius: 100.0,
      ),
    );
    // Initialize with a default 300x200 box path
    _controller.initializeParticles(
      Path()..addRect(const Rect.fromLTWH(0, 0, 320, 200)),
      config,
    );
  }

  @override
  void dispose() {
    _fpsTicker.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _triggerStressTest() {
    if (!_controller.isEnabled) return;
    for (int i = 0; i < 12; i++) {
      // Simulate rapid tapping at random locations inside the bounds
      final randomX = 20.0 + math.Random().nextDouble() * 280.0;
      final randomY = 20.0 + math.Random().nextDouble() * 160.0;
      _controller.toggle(Offset(randomX, randomY));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int particleCount = _controller.particleCount;
    final int activeWaves = _controller.activeWavesCount;
    final String backend = _controller.renderBackend.name.toUpperCase();

    // Theoretical listener comparison
    final int oldListeners = particleCount * activeWaves;
    final int newListeners = activeWaves;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Performance Benchmark'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FPS Meter & Real-time Stats Card
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Telemetry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _fps > 55
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_fps.toStringAsFixed(1)} FPS',
                            style: TextStyle(
                              color: _fps > 55
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _TelemetryRow('Active Particles:', '$particleCount'),
                    _TelemetryRow('Active Waves:', '$activeWaves'),
                    _TelemetryRow('Drawing Strategy:', backend),
                    const Divider(color: Colors.white12, height: 20),
                    const Text(
                      'CONCURRENT ANIMATION LISTENERS',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TelemetryRow(
                      'Previous Design:',
                      '$oldListeners (1 per particle per wave)',
                      labelColor: Colors.redAccent,
                    ),
                    _TelemetryRow(
                      'Optimized Design:',
                      '$newListeners (1 per wave total)',
                      labelColor: Colors.greenAccent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Interactive Preview
            Center(
              child: Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Background grid
                      Positioned.fill(
                        child: GridPaper(
                          color: Colors.white.withValues(alpha: 0.05),
                          interval: 50.0,
                          divisions: 2,
                        ),
                      ),
                      // Interactive SpoilerOverlay
                      Positioned.fill(
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) {
                            return SpoilerOverlay(
                              config: WidgetSpoilerConfig(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                maxActiveWaves: _maxActiveWaves,
                                isEnabled: true,
                                enableGestureReveal:
                                    true, // Let user tap to spawn wave
                                particleConfig: ParticleConfig(
                                  density: _density,
                                  speed: _speed,
                                  color: Colors.cyanAccent,
                                  maxParticleSize: _maxParticleSize,
                                  enableWaves: _enableWaves,
                                  maxWaveRadius: 100.0,
                                ),
                              ),
                              child: Container(
                                color: Colors.blueGrey[900],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        size: 48,
                                        color: Colors.white54,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Interactive Spoiler',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Tap to trigger waves',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions & Controllers Card
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _triggerStressTest,
                      icon: const Icon(Icons.flash_on),
                      label: const Text(
                        'Spawn 12 Waves Simultaneously',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Adjust Parameters',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SliderRow(
                      label: 'Particle Density',
                      value: _density,
                      min: 0.05,
                      max: 0.8,
                      onChanged: (val) {
                        setState(() {
                          _density = val;
                          _initializeController();
                        });
                      },
                    ),
                    _SliderRow(
                      label: 'Particle Size (Max)',
                      value: _maxParticleSize,
                      min: 1.0,
                      max: 8.0,
                      onChanged: (val) {
                        setState(() {
                          _maxParticleSize = val;
                          _initializeController();
                        });
                      },
                    ),
                    _SliderRow(
                      label: 'Particle Speed',
                      value: _speed,
                      min: 0.1,
                      max: 2.0,
                      onChanged: (val) {
                        setState(() {
                          _speed = val;
                          _initializeController();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  const _TelemetryRow(this.label, this.value, {this.labelColor});
  final String label;
  final String value;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor ?? Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
