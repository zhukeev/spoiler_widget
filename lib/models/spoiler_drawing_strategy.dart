import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/utils/image_factory.dart';
import 'package:spoiler_widget/utils/spoiler_shader_renderer.dart';
import 'package:spoiler_widget/extension/path_x.dart';

/// Context object containing all state required for drawing the spoiler.
class SpoilerContext {
  const SpoilerContext({
    required this.isFading,
    required this.fadeRadius,
    required this.fadeCenter,
    required this.spoilerPath,
    required this.spoilerBounds,
    required this.spoilerRects,
    required this.config,
  });

  final bool isFading;
  final double fadeRadius;
  final Offset fadeCenter;
  final Path spoilerPath;
  final Rect spoilerBounds;
  final List<Rect> spoilerRects;
  final SpoilerConfig config;
}

/// Abstract strategy for drawing particles.
abstract class SpoilerDrawer {
  /// Returns true if the drawer has drawable content (e.g., particles).
  bool get hasContent;

  /// Exposes particle list if applicable (Atlas), otherwise empty.
  List<Particle> get particles;

  void update(double dt);

  void draw(
    Canvas canvas,
    SpoilerContext context,
  );

  void dispose();
}

/// Strategy for drawing particles using a custom shader.
class ShaderSpoilerDrawer implements SpoilerDrawer {
  ShaderSpoilerDrawer._(this._renderer);

  final SpoilerShaderRenderer _renderer;
  double _shaderTime = 0.0;

  static Future<ShaderSpoilerDrawer> create(String assetPath) async {
    final renderer = await SpoilerShaderRenderer.create(assetPath);
    if (renderer == null) {
      throw Exception('Failed to load shader from $assetPath');
    }
    return ShaderSpoilerDrawer._(renderer);
  }

  @override
  bool get hasContent => true;

  @override
  List<Particle> get particles => const [];

  @override
  void update(double dt) {
    _shaderTime += dt;
  }

  @override
  void draw(
    Canvas canvas,
    SpoilerContext context,
  ) {
    // Get global translation and scale from canvas matrix
    final transform = canvas.getTransform();
    final double dpr = transform[0];

    final isFading = context.isFading;
    final fadeRadius = context.fadeRadius;
    final fadeCenter = context.fadeCenter;
    final spoilerPath = context.spoilerPath;
    final spoilerBounds = context.spoilerBounds;
    final spoilerRects = context.spoilerRects;
    final config = context.config;

    final Rect logicalBounds = spoilerBounds;

    if (spoilerRects.isEmpty) {
      // Fallback if no rects
      canvas.save();

      if (isFading && fadeRadius > 0) {
        final circlePath = Path()
          ..addOval(
            Rect.fromCircle(center: fadeCenter, radius: fadeRadius),
          );
        final clipPath = Path.combine(
          PathOperation.intersect,
          spoilerPath,
          circlePath,
        );
        canvas.clipPath(clipPath);
      } else {
        // When fade is disabled or radius is tiny, draw full bounds.
        canvas.clipRect(spoilerBounds);
      }

      final physicalConfig = config.copyWith(
        maxParticleSize: config.particleConfig.maxParticleSize * dpr,
        particleSpeed: config.particleConfig.speed * dpr,
        particleDensity: config.particleConfig.density / (dpr * dpr),
      );

      // Scale rect and fade values to device pixels so uniforms align with fragment coords.
      final Rect spoilerBoundsPx = Rect.fromLTWH(
        spoilerBounds.left * dpr,
        spoilerBounds.top * dpr,
        spoilerBounds.width * dpr,
        spoilerBounds.height * dpr,
      );

      // Keep callback in logical space for backward compatibility.
      final params = (config.shaderConfig?.onGetShaderUniforms?.call(
                logicalBounds,
                _shaderTime,
                0.0,
                fadeCenter,
                isFading,
                physicalConfig,
              ) ??
              <double>[])
          .toList();

      _renderer.render(
        canvas,
        spoilerBoundsPx,
        _shaderTime,
        seed: 0.0,
        params: params,
      );
      canvas.restore();
      return;
    }

    int i = 0;
    for (final rect in spoilerRects) {
      final seed = i * 123.45 + rect.left + rect.top;

      canvas.save();

      if (isFading && fadeRadius > 0) {
        final rectPath = Path()..addRect(rect);
        final circlePath = Path()
          ..addOval(
            Rect.fromCircle(center: fadeCenter, radius: fadeRadius),
          );

        final clipPath = Path.combine(
          PathOperation.intersect,
          rectPath,
          circlePath,
        );

        canvas.clipPath(clipPath);
      } else {
        // Draw the full rect when fade is disabled or radius is tiny.
        canvas.clipRect(rect);
      }

      final physicalConfig = config.copyWith(
        maxParticleSize: config.particleConfig.maxParticleSize * dpr,
        particleSpeed: config.particleConfig.speed * dpr,
        particleDensity: config.particleConfig.density / (dpr * dpr),
      );
      // Scale rect and fade values to device pixels so uniforms align with fragment coords.
      final Rect rectPx = Rect.fromLTWH(
        rect.left * dpr,
        rect.top * dpr,
        rect.width * dpr,
        rect.height * dpr,
      );

      // Keep callback in logical space for backward compatibility.
      final params = (config.shaderConfig?.onGetShaderUniforms?.call(
                rect,
                _shaderTime,
                seed,
                fadeCenter,
                isFading,
                physicalConfig,
              ) ??
              <double>[])
          .toList();

      _renderer.render(
        canvas,
        rectPx,
        _shaderTime,
        seed: seed,
        params: params,
      );

      canvas.restore();
      i++;
    }
  }

  @override
  void dispose() {
    // Renderer is likely shared or managed elsewhere, but here
    // we assume the controller manages its lifecycle or we can dispose it.
    // Actually SpoilerShaderRenderer.create returns a new instance usually.
    // But Controller caches it. Let's leave it no-op
    // or let the controller dispose the actual renderer instance if it owns it.
  }
}

/// Strategy for drawing particles using Flutter's drawRawAtlas (CPU/hybrid).
class AtlasSpoilerDrawer implements SpoilerDrawer {
  AtlasSpoilerDrawer();

  // Particle state
  final Random _random = Random();
  final List<Particle> _particles = [];

  // Visual assets & config
  CircleImage _circleImage = CircleImageFactory.create(diameter: 1, color: Colors.white);
  double _maxParticleSize = 1;
  Color _particleColor = Colors.white;
  double _particleSpeed = 1;

  // buffers
  Float32List? _valTransforms;
  Float32List? _valRects;
  Int32List? _valColors;
  int _lastParticleCount = 0;

  final Paint _particlePaint = Paint();

  @override
  bool get hasContent => _particles.isNotEmpty;

  @override
  List<Particle> get particles => _particles;

  void _reallocBuffers(int count) {
    if (count == _lastParticleCount && _valTransforms != null) return;
    _valTransforms = Float32List(count * 4);
    _valRects = Float32List(count * 4);
    _valColors = Int32List(count);
    _lastParticleCount = count;
  }

  void updateCircleImage(CircleImage newImage) {
    _circleImage = newImage;
  }

  void initializeParticles({
    required Iterable<Path> paths,
    required SpoilerConfig config,
  }) {
    _particles.clear();
    _maxParticleSize = config.particleConfig.maxParticleSize;
    _particleColor = config.particleConfig.color;
    _particleSpeed = config.particleConfig.speed;

    // Refresh circle image to match config
    _circleImage = CircleImageFactory.create(
      diameter: _maxParticleSize,
      color: _particleColor,
    );

    for (final path in paths) {
      final rect = path.getBounds();
      final particleCount = (rect.width * rect.height) * config.particleConfig.density;
      for (int i = 0; i < particleCount; i++) {
        _particles.add(_createRandomParticlePath(path));
      }
    }
    _reallocBuffers(_particles.length);
  }

  @override
  void update(double dt) {
    if (_particles.isEmpty) return;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      _particles[i] = (p.life <= 0.1) ? _createRandomParticlePath(p.path) : p.moveToRandomAngle();
    }
  }

  Particle _createRandomParticlePath(Path path) {
    final offset = path.getRandomPoint();
    return Particle(
      offset.dx,
      offset.dy,
      _maxParticleSize,
      _particleColor,
      _random.nextDouble(), // life
      _particleSpeed, // velocity
      _random.nextDouble() * 2 * pi, // angle
      path,
    );
  }

  @override
  void draw(
    Canvas canvas,
    SpoilerContext context,
  ) {
    final isFading = context.isFading;
    final fadeRadius = context.fadeRadius;
    final fadeCenter = context.fadeCenter;
    final fadeEdgeThickness = context.config.fadeConfig?.edgeThickness ?? 1;
    _maxParticleSize = context.config.particleConfig.maxParticleSize;
    _particleColor = context.config.particleConfig.color;
    _particleSpeed = context.config.particleConfig.speed;

    final count = _particles.length;
    if (count == 0) return;

    _reallocBuffers(count);

    final transforms = _valTransforms!;
    final rects = _valRects!;
    final colors = _valColors!;

    int index = 0;
    for (final p in _particles) {
      final transformIndex = index * 4;

      if (isFading) {
        final distSq = (fadeCenter - p).distanceSquared;
        final radiusSq = fadeRadius * fadeRadius;

        if (distSq < radiusSq) {
          final dist = sqrt(distSq);
          final scale = (dist > fadeRadius - fadeEdgeThickness) ? 1.5 : 1.0;
          final color = (dist > fadeRadius - fadeEdgeThickness) ? Colors.white : p.color;

          transforms[transformIndex + 0] = scale;
          transforms[transformIndex + 1] = 0.0;
          transforms[transformIndex + 2] = p.dx;
          transforms[transformIndex + 3] = p.dy;

          rects[transformIndex + 0] = 0.0;
          rects[transformIndex + 1] = 0.0;
          rects[transformIndex + 2] = _circleImage.dimension.toDouble();
          rects[transformIndex + 3] = _circleImage.dimension.toDouble();

          // ignore: deprecated_member_use
          colors[index] = color.value;
          index++;
        } else {
          // outside fade circle
          // ignore: deprecated_member_use
          colors[index] = Colors.transparent.value;
          transforms[transformIndex + 0] = 0;
          index++;
        }
      } else {
        // normal
        transforms[transformIndex + 0] = 1.0;
        transforms[transformIndex + 1] = 0.0;
        transforms[transformIndex + 2] = p.dx;
        transforms[transformIndex + 3] = p.dy;

        rects[transformIndex + 0] = 0.0;
        rects[transformIndex + 1] = 0.0;
        rects[transformIndex + 2] = _circleImage.dimension.toDouble();
        rects[transformIndex + 3] = _circleImage.dimension.toDouble();

        // ignore: deprecated_member_use
        colors[index] = p.color.value;
        index++;
      }
    }

    if (index > 0) {
      canvas.drawRawAtlas(
        _circleImage.image,
        transforms,
        rects,
        colors,
        BlendMode.srcOver,
        null,
        _particlePaint,
      );
    }
  }

  @override
  void dispose() {
    _valTransforms = null;
    _valRects = null;
    _valColors = null;
    _particles.clear();
  }
}
