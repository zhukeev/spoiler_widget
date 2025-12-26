import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

class SpoilerPerformancePage extends StatefulWidget {
  const SpoilerPerformancePage({super.key});

  @override
  State<SpoilerPerformancePage> createState() => _SpoilerPerformancePageState();
}

class _SpoilerPerformancePageState extends State<SpoilerPerformancePage> {
  double _density = 0.1;
  double _updateInterval = 0.0;
  double _maxParticleSize = 1.0;

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = TextSpoilerConfig(
      isEnabled: true,
      enableGestureReveal: true,
      fadeConfig: const FadeConfig(padding: 10.0, edgeThickness: 20.0),
      particleConfig: ParticleConfig(
        density: _density,
        speed: 0.25,
        color: Colors.white,
        maxParticleSize: _maxParticleSize,
        updateInterval: _updateInterval,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSlider(
                    label: 'Density',
                    value: _density,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        _density = value;
                      });
                    },
                  ),
                  _buildSlider(
                    label: 'Update interval (s)',
                    value: _updateInterval,
                    min: 0.0,
                    max: 0.5,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _updateInterval = value;
                      });
                    },
                  ),
                  _buildSlider(
                    label: 'Max particle size',
                    value: _maxParticleSize,
                    min: 1.0,
                    max: 6.0,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _maxParticleSize = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SpoilerTextWrapper(
                  config: config,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Performance tuning',
                        style: TextStyle(fontSize: 28, color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Adjust density, update interval, and particle size.',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
