import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/path_x.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/utils/image_factory.dart';
import 'package:spoiler_widget/utils/spoiler_shader_renderer.dart';

/// Context object containing all state required for drawing the spoiler.
class SpoilerContext {
  const SpoilerContext({
    required this.isFading,
    required this.fadeRadius,
    required this.fadeCenter,
    required this.spoilerBounds,
    required this.spoilerRects,
    required this.config,
  });

  final bool isFading;
  final double fadeRadius;
  final Offset fadeCenter;
  final Rect spoilerBounds;
  final List<Rect> spoilerRects;
  final SpoilerConfig config;
}

enum ParticleRenderBackend {
  shader,
  atlas,
  vector,
}

class AtlasSupportPolicy {
  const AtlasSupportPolicy({
    required this.isEligible,
    required this.rasterDiameter,
  });

  final bool isEligible;
  final double rasterDiameter;
}

const double _minAtlasRasterDiameter = 2.0;

AtlasSupportPolicy atlasSupportPolicyFor(ParticleConfig config) {
  final rasterDiameter = max(
    config.maxParticleSize.ceilToDouble(),
    _minAtlasRasterDiameter,
  );
  return AtlasSupportPolicy(
    isEligible: config.maxParticleSize > 1.0,
    rasterDiameter: rasterDiameter,
  );
}

typedef CircleImageBuilder = CircleImage Function({
  required double diameter,
  required ui.Color color,
  ui.Path? shapePath,
  double? rasterDiameter,
});

typedef RawAtlasPainter = void Function({
  required Canvas canvas,
  required ui.Image atlas,
  required Float32List transforms,
  required Float32List rects,
  Int32List? colors,
  BlendMode? blendMode,
  Rect? cullRect,
  required Paint paint,
});

CircleImage _defaultCircleImageBuilder({
  required double diameter,
  required ui.Color color,
  ui.Path? shapePath,
  double? rasterDiameter,
}) {
  return CircleImageFactory.create(
    diameter: diameter,
    color: color,
    shapePath: shapePath,
    rasterDiameter: rasterDiameter,
  );
}

void _defaultRawAtlasPainter({
  required Canvas canvas,
  required ui.Image atlas,
  required Float32List transforms,
  required Float32List rects,
  Int32List? colors,
  BlendMode? blendMode,
  Rect? cullRect,
  required Paint paint,
}) {
  canvas.drawRawAtlas(
    atlas,
    transforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );
}

@visibleForTesting
CircleImageBuilder debugCircleImageBuilder = _defaultCircleImageBuilder;

@visibleForTesting
RawAtlasPainter debugRawAtlasPainter = _defaultRawAtlasPainter;

/// Abstract strategy for drawing particles.
abstract class SpoilerDrawer {
  /// Returns true if the drawer has drawable content (e.g., particles).
  bool get hasContent;

  /// Exposes particle list if applicable (Atlas/Vector), otherwise empty.
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
  CircleImage? _sprite;
  ParticleConfig? _spriteConfig;

  static const String _particlesShaderPath =
      'packages/spoiler_widget/shaders/particles.frag';

  static bool _isParticleShaderPath(String? path) {
    if (path == null) return false;
    if (path == _particlesShaderPath) return true;
    return path.endsWith('particles.frag');
  }

  CircleImage _ensureSprite(ParticleConfig config) {
    if (_sprite == null || _spriteConfig != config) {
      _spriteConfig = config;
      _sprite = debugCircleImageBuilder(
        diameter: config.maxParticleSize,
        color: Colors.white,
        shapePath: config.shapePreset?.path,
        rasterDiameter: atlasSupportPolicyFor(config).rasterDiameter,
      );
    }
    return _sprite!;
  }

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
    final isFading = context.isFading;
    final fadeRadius = context.fadeRadius;
    final fadeCenter = context.fadeCenter;
    final spoilerBounds = context.spoilerBounds;
    final spoilerRects = context.spoilerRects;
    final config = context.config;
    final bool isParticleShader =
        _isParticleShaderPath(config.shaderConfig?.customShaderPath);
    final CircleImage? sprite =
        isParticleShader ? _ensureSprite(config.particleConfig) : null;

    final Rect logicalBounds = spoilerBounds;

    if (spoilerRects.isEmpty) {
      canvas.save();
      canvas.clipRect(spoilerBounds);

      final params = (config.shaderConfig?.onGetShaderUniforms?.call(
                logicalBounds,
                _shaderTime,
                0.0,
                fadeCenter,
                isFading,
                fadeRadius,
                config,
              ) ??
              <double>[])
          .toList();

      _renderer.render(
        canvas,
        spoilerBounds,
        _shaderTime,
        seed: 0.0,
        params: params,
        images: sprite == null ? null : [sprite.image],
      );
      canvas.restore();
      return;
    }

    int i = 0;
    for (final rect in spoilerRects) {
      final seed = i * 123.45 + rect.left + rect.top;

      canvas.save();
      canvas.clipRect(rect);

      final params = (config.shaderConfig?.onGetShaderUniforms?.call(
                rect,
                _shaderTime,
                seed,
                fadeCenter,
                isFading,
                fadeRadius,
                config,
              ) ??
              <double>[])
          .toList();

      _renderer.render(
        canvas,
        rect,
        _shaderTime,
        seed: seed,
        params: params,
        images: sprite == null ? null : [sprite.image],
      );

      canvas.restore();
      i++;
    }
  }

  @override
  void dispose() {}
}

int _channelToInt8(double value) =>
    (value * 255.0).round().clamp(0, 255).toInt();

int _colorToArgb(Color color) {
  return (_channelToInt8(color.a) << 24) |
      (_channelToInt8(color.r) << 16) |
      (_channelToInt8(color.g) << 8) |
      _channelToInt8(color.b);
}

class _ParticleVisual {
  const _ParticleVisual({
    required this.scale,
    required this.color,
  });

  final double scale;
  final Color color;
}

abstract class ParticleSpoilerDrawer implements SpoilerDrawer {
  static const double lifeSizeMin = 0.6;

  final Random _random = Random();
  final List<Particle> _particles = [];

  double _maxParticleSize = 1.0;
  Color _particleColor = Colors.white;
  double _particleSpeed = 1.0;
  Path? _shapePath;

  @override
  bool get hasContent => _particles.isNotEmpty;

  @override
  List<Particle> get particles => _particles;

  ParticleRenderBackend get backend;

  double get maxParticleSize => _maxParticleSize;
  Color get particleColor => _particleColor;
  double get particleSpeed => _particleSpeed;
  Path? get shapePath => _shapePath;

  void initializeParticles({
    required Iterable<Path> paths,
    required SpoilerConfig config,
  }) {
    _particles.clear();
    _maxParticleSize = config.particleConfig.maxParticleSize;
    _particleColor = config.particleConfig.color;
    _particleSpeed = config.particleConfig.speed;
    _shapePath = config.particleConfig.shapePreset?.path;

    final coverage = config.particleConfig.density.clamp(0.0, 1.0);

    for (final path in paths) {
      final rect = path.getBounds();
      final screenArea = rect.width * rect.height;
      final particleArea = pi *
          pow(config.particleConfig.maxParticleSize * 0.5, 2) *
          config.particleConfig.areaFactor;

      final rawCount = (screenArea * coverage) / particleArea;
      final particleCount = rawCount.round();
      if (particleCount <= 0) {
        continue;
      }

      for (int i = 0; i < particleCount; i++) {
        _particles.add(_createRandomParticlePath(path));
      }
    }
    onParticlesInitialized();
  }

  @protected
  void onParticlesInitialized() {}

  void adoptStateFrom(ParticleSpoilerDrawer other) {
    _particles
      ..clear()
      ..addAll(other._particles);
    _maxParticleSize = other._maxParticleSize;
    _particleColor = other._particleColor;
    _particleSpeed = other._particleSpeed;
    _shapePath = other._shapePath;
    onParticlesInitialized();
  }

  @override
  void update(double dt) {
    if (_particles.isEmpty) return;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      _particles[i] = (p.life <= 0.1)
          ? _createRandomParticlePath(p.path)
          : p.moveToRandomAngle();
    }
  }

  Particle _createRandomParticlePath(Path path) {
    final offset = path.getRandomPoint();
    return Particle(
      offset.dx,
      offset.dy,
      _maxParticleSize,
      _particleColor,
      _random.nextDouble(),
      _particleSpeed,
      _random.nextDouble() * 2 * pi,
      path,
    );
  }

  @protected
  _ParticleVisual? buildParticleVisual(
    Particle particle,
    SpoilerContext context, {
    required double baseRadius,
  }) {
    final fadeEdgeThickness = context.config.fadeConfig?.edgeThickness ?? 1.0;
    final bounds = context.spoilerBounds;
    final boundaryFadePx = max(baseRadius * 3.0, 6.0);

    double smoothstep(double edge0, double edge1, double x) {
      final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
      return t * t * (3.0 - 2.0 * t);
    }

    final lifeScale = lifeSizeMin + (1.0 - lifeSizeMin) * particle.life;
    final edgeDist = min(
      min(particle.dx - bounds.left, bounds.right - particle.dx),
      min(particle.dy - bounds.top, bounds.bottom - particle.dy),
    );
    final edgeFade =
        edgeDist <= 0.0 ? 0.0 : smoothstep(0.0, boundaryFadePx, edgeDist);
    final particleRadius = max(baseRadius * lifeScale, 0.0001);
    final edgeClamp = (edgeDist / particleRadius).clamp(0.0, 1.0);
    final edgeScale = edgeFade * edgeClamp;

    if (edgeScale <= 0.0) {
      return null;
    }

    if (context.isFading) {
      final distSq = (context.fadeCenter - particle).distanceSquared;
      final radiusSq = context.fadeRadius * context.fadeRadius;
      if (distSq >= radiusSq) {
        return null;
      }

      final dist = sqrt(distSq);
      final highlight = dist > context.fadeRadius - fadeEdgeThickness;
      final tint = highlight ? Colors.white : particle.color;
      final scaled = (highlight ? 1.5 : 1.0) * lifeScale * edgeScale;
      if (scaled <= 0.0) {
        return null;
      }

      return _ParticleVisual(
        scale: scaled,
        color: tint.withValues(alpha: tint.a * edgeScale),
      );
    }

    final scaled = lifeScale * edgeScale;
    if (scaled <= 0.0) {
      return null;
    }

    return _ParticleVisual(
      scale: scaled,
      color: particle.color.withValues(alpha: particle.color.a * edgeScale),
    );
  }

  @override
  void dispose() {
    _particles.clear();
  }
}

/// Strategy for drawing particles using Flutter's drawRawAtlas (CPU/hybrid).
class AtlasSpoilerDrawer extends ParticleSpoilerDrawer {
  CircleImage? _circleImage;
  Float32List? _valTransforms;
  Float32List? _valRects;
  Int32List? _valColors;
  int _lastParticleCount = 0;

  final Paint _particlePaint = Paint();
  double _rasterDiameter = _minAtlasRasterDiameter;

  @override
  ParticleRenderBackend get backend => ParticleRenderBackend.atlas;

  @override
  void onParticlesInitialized() {
    _circleImage = null;
    _rasterDiameter =
        max(maxParticleSize.ceilToDouble(), _minAtlasRasterDiameter);
    _reallocBuffers(particles.length);
  }

  void _reallocBuffers(int count) {
    if (count == _lastParticleCount && _valTransforms != null) return;
    _valTransforms = Float32List(count * 4);
    _valRects = Float32List(count * 4);
    _valColors = Int32List(count);
    _lastParticleCount = count;
  }

  CircleImage ensureSprite() {
    return _circleImage ??= debugCircleImageBuilder(
      diameter: maxParticleSize,
      color: Colors.white,
      shapePath: shapePath,
      rasterDiameter: _rasterDiameter,
    );
  }

  @override
  void draw(
    Canvas canvas,
    SpoilerContext context,
  ) {
    final count = particles.length;
    if (count == 0) return;

    _reallocBuffers(count);
    final sprite = ensureSprite();
    final transforms = _valTransforms!;
    final rects = _valRects!;
    final colors = _valColors!;
    final spriteRadius = sprite.rasterDimension * 0.5;

    for (int index = 0; index < count; index++) {
      final particle = particles[index];
      final transformIndex = index * 4;
      final visual = buildParticleVisual(
        particle,
        context,
        baseRadius: particle.size * 0.5,
      );

      rects[transformIndex + 0] = 0.0;
      rects[transformIndex + 1] = 0.0;
      rects[transformIndex + 2] = sprite.rasterDimension;
      rects[transformIndex + 3] = sprite.rasterDimension;

      if (visual == null) {
        transforms[transformIndex + 0] = 0.0;
        transforms[transformIndex + 1] = 0.0;
        transforms[transformIndex + 2] = 0.0;
        transforms[transformIndex + 3] = 0.0;
        colors[index] = _colorToArgb(Colors.transparent);
        continue;
      }

      transforms[transformIndex + 0] = visual.scale;
      transforms[transformIndex + 1] = 0.0;
      transforms[transformIndex + 2] =
          particle.dx - spriteRadius * visual.scale;
      transforms[transformIndex + 3] =
          particle.dy - spriteRadius * visual.scale;
      colors[index] = _colorToArgb(visual.color);
    }

    debugRawAtlasPainter(
      canvas: canvas,
      atlas: sprite.image,
      transforms: transforms,
      rects: rects,
      colors: colors,
      blendMode: BlendMode.modulate,
      cullRect: null,
      paint: _particlePaint,
    );
  }

  @override
  void dispose() {
    _valTransforms = null;
    _valRects = null;
    _valColors = null;
    _circleImage = null;
    super.dispose();
  }
}

class VectorSpoilerDrawer extends ParticleSpoilerDrawer {
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  @override
  ParticleRenderBackend get backend => ParticleRenderBackend.vector;

  @override
  void draw(
    Canvas canvas,
    SpoilerContext context,
  ) {
    if (particles.isEmpty) return;

    final shape = shapePath;

    for (final particle in particles) {
      final visual = buildParticleVisual(
        particle,
        context,
        baseRadius: particle.size * 0.5,
      );
      if (visual == null) {
        continue;
      }

      _particlePaint.color = visual.color;
      final radius = particle.size * 0.5 * visual.scale;

      if (shape == null) {
        canvas.drawCircle(particle, radius, _particlePaint);
        continue;
      }

      canvas.save();
      canvas.translate(particle.dx, particle.dy);
      canvas.scale(radius, radius);
      canvas.drawPath(shape, _particlePaint);
      canvas.restore();
    }
  }
}
