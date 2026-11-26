import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

/// Backend strategies for particle rendering:
/// - [shader]: Uses a custom GLSL fragment shader (e.g., 'particles.frag')
///   to generate particle effects procedurally.
/// - [atlas]: Uses a pre-rendered sprite atlas (array of circle images) for
///   efficient batch rendering.
/// - [vector]: Renders particles as individual vector shapes (paths) without
///   using a sprite atlas.
enum ParticleRenderBackend { shader, atlas, vector, vertices }

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
  // Custom shape presets are rendered via vector path drawing, not atlas
  // rasterization, so mark them ineligible for the atlas backend.
  final isEligible = config.maxParticleSize > 1.0 && config.shapePreset == null;
  return AtlasSupportPolicy(
    isEligible: isEligible,
    rasterDiameter: rasterDiameter,
  );
}

typedef CircleImageBuilder =
    CircleImage Function({
      required double diameter,
      required ui.Color color,
      ui.Path? shapePath,
      double? rasterDiameter,
    });

typedef RawAtlasPainter =
    void Function({
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

  void draw(Canvas canvas, SpoilerContext context);

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
    // Only a shader that keeps the bundled filename declares the sprite
    // sampler — a loose endsWith also matched names like my_particles.frag
    // and would inject an unwanted uniform.
    return path.split('/').last == 'particles.frag';
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
  void draw(Canvas canvas, SpoilerContext context) {
    final isFading = context.isFading;
    final fadeRadius = context.fadeRadius;
    final fadeCenter = context.fadeCenter;
    final spoilerBounds = context.spoilerBounds;
    final spoilerRects = context.spoilerRects;
    final config = context.config;
    final bool isParticleShader = _isParticleShaderPath(
      config.shaderConfig?.customShaderPath,
    );
    final CircleImage? sprite = isParticleShader
        ? _ensureSprite(config.particleConfig)
        : null;

    final Rect logicalBounds = spoilerBounds;

    if (spoilerRects.isEmpty) {
      canvas.save();
      canvas.clipRect(spoilerBounds);

      final params =
          config.shaderConfig?.onGetShaderUniforms?.call(
            logicalBounds,
            _shaderTime,
            0.0,
            fadeCenter,
            isFading,
            fadeRadius,
            config,
          ) ??
          const <double>[];

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

      final params =
          config.shaderConfig?.onGetShaderUniforms?.call(
            rect,
            _shaderTime,
            seed,
            fadeCenter,
            isFading,
            fadeRadius,
            config,
          ) ??
          const <double>[];

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

class ParticleVisual {
  const ParticleVisual({required this.scale, required this.color});

  final double scale;
  final Color color;
}

abstract class ParticleSpoilerDrawer implements SpoilerDrawer {
  static const double lifeSizeMin = 0.6;

  /// Optional fixed seed for the particle random source.
  ///
  /// Set this in tests for reproducible particle layouts (e.g. golden
  /// images). Leave null in production for nondeterministic placement.
  static int? debugRandomSeed;

  final Random _random = Random(debugRandomSeed);
  final List<Particle> _particles = [];

  /// Pre-validated spawn positions per source path. Respawns pick from the
  /// pool instead of running the unbounded `contains()` rejection loop in
  /// [PathX.getRandomPoint] every frame.
  final Map<Path, List<Offset>> _pointPools = {};

  static const int _pointPoolTargetSize = 1024;
  static const int _pointPoolSampleAttempts = 8192;

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
    _pointPools.clear();
    _maxParticleSize = config.particleConfig.maxParticleSize;
    _particleColor = config.particleConfig.color;
    _particleSpeed = config.particleConfig.speed;
    _shapePath = config.particleConfig.shapePreset?.path;

    final coverage = config.particleConfig.density.clamp(0.0, 1.0);

    for (final path in paths) {
      final rect = path.getBounds();
      final screenArea = rect.width * rect.height;
      final particleArea =
          pi *
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

    // dt is elapsed seconds; normalize to 60 fps frame units so particle
    // motion and life decay stay frame-rate independent.
    final step = dt * 60.0;
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      _particles[i] = (p.life <= 0.1)
          ? _createRandomParticlePath(p.path)
          : p.moveToRandomAngle(_random, step);
    }
  }

  List<Offset> _pointPoolFor(Path path) {
    return _pointPools.putIfAbsent(path, () => _buildPointPool(path));
  }

  List<Offset> _buildPointPool(Path path) {
    final bounds = path.getBounds();
    final points = <Offset>[];
    for (
      var attempt = 0;
      attempt < _pointPoolSampleAttempts &&
          points.length < _pointPoolTargetSize;
      attempt++
    ) {
      final candidate = Offset(
        bounds.left + _random.nextDouble() * bounds.width,
        bounds.top + _random.nextDouble() * bounds.height,
      );
      if (path.contains(candidate)) points.add(candidate);
    }
    // Path contains nothing (degenerate/empty): park particles at the bounds
    // center rather than looping forever.
    if (points.isEmpty) points.add(bounds.center);
    return points;
  }

  Particle _createRandomParticlePath(Path path) {
    final pool = _pointPoolFor(path);
    final offset = pool[_random.nextInt(pool.length)];
    return Particle(
      Particle.generateId(),
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
  ParticleVisual? buildParticleVisual(
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
    final edgeFade = edgeDist <= 0.0
        ? 0.0
        : smoothstep(0.0, boundaryFadePx, edgeDist);
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

      return ParticleVisual(
        scale: scaled,
        color: tint.withValues(alpha: tint.a * edgeScale),
      );
    }

    final scaled = lifeScale * edgeScale;
    if (scaled <= 0.0) {
      return null;
    }

    return ParticleVisual(
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
    _rasterDiameter = max(
      maxParticleSize.ceilToDouble(),
      _minAtlasRasterDiameter,
    );
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
  void draw(Canvas canvas, SpoilerContext context) {
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
      // Inflate by the sprite extent so edge particles aren't culled while
      // their scaled sprite still overlaps the bounds.
      cullRect: context.spoilerBounds.inflate(spriteRadius),
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
  FittedPathMetrics? _shapeMetrics;

  @override
  ParticleRenderBackend get backend => ParticleRenderBackend.vector;

  @override
  void onParticlesInitialized() {
    final currentShape = shapePath;
    _shapeMetrics = currentShape == null
        ? null
        : fittedPathMetricsFor(currentShape);
  }

  @override
  void draw(Canvas canvas, SpoilerContext context) {
    if (particles.isEmpty) return;

    final shape = shapePath;
    final shapeMetrics = _shapeMetrics;

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
      if (shapeMetrics == null || !shapeMetrics.isDrawable) {
        continue;
      }

      drawFittedPath(
        canvas,
        shape,
        center: particle,
        targetDiameter: radius * 2.0,
        paint: _particlePaint,
        metrics: shapeMetrics,
      );
    }
  }
}

/// Strategy for drawing particles as a single triangulated mesh via
/// [Canvas.drawVertices].
///
/// Each particle becomes an octagon fan (a close enough disc at particle
/// sizes) with per-vertex RGBA, so individual scale, tint and alpha survive
/// batching — unlike [Canvas.drawPoints], which shares one [Paint] across
/// all points. This exists mainly as a fast-path candidate for configs that
/// would otherwise fall back to per-particle vector drawing.
class VerticesSpoilerDrawer extends ParticleSpoilerDrawer {
  static const int _sides = 8;
  static const int _vertsPerParticle = _sides * 3;

  /// Unit-circle ring vertices; index [_sides] duplicates index 0 so each
  /// fan segment reads two consecutive entries.
  static final List<Offset> _ring = List<Offset>.generate(
    _sides + 1,
    (i) => Offset(cos(2 * pi * i / _sides), sin(2 * pi * i / _sides)),
  );

  final Paint _particlePaint = Paint();
  Float32List? _positions;
  Int32List? _colors;
  int _lastParticleCount = 0;

  @override
  ParticleRenderBackend get backend => ParticleRenderBackend.vertices;

  @override
  void onParticlesInitialized() {
    _reallocBuffers(particles.length);
  }

  void _reallocBuffers(int count) {
    if (count == _lastParticleCount && _positions != null) return;
    _positions = Float32List(count * _vertsPerParticle * 2);
    _colors = Int32List(count * _vertsPerParticle);
    _lastParticleCount = count;
  }

  @override
  void draw(Canvas canvas, SpoilerContext context) {
    final count = particles.length;
    if (count == 0) return;

    _reallocBuffers(count);
    final positions = _positions!;
    final colors = _colors!;
    final transparent = _colorToArgb(Colors.transparent);

    for (var index = 0; index < count; index++) {
      final particle = particles[index];
      final visual = buildParticleVisual(
        particle,
        context,
        baseRadius: particle.size * 0.5,
      );

      var v = index * _vertsPerParticle * 2;
      var c = index * _vertsPerParticle;

      if (visual == null) {
        // Degenerate (zero-area, transparent) triangles — keeps buffer
        // layout fixed so no sublist copy is needed per frame.
        for (var t = 0; t < _vertsPerParticle; t++) {
          positions[v] = 0;
          positions[v + 1] = 0;
          v += 2;
          colors[c++] = transparent;
        }
        continue;
      }

      final radius = particle.size * 0.5 * visual.scale;
      final argb = _colorToArgb(visual.color);
      final cx = particle.dx;
      final cy = particle.dy;

      for (var s = 0; s < _sides; s++) {
        final p1 = _ring[s];
        final p2 = _ring[s + 1];
        positions[v++] = cx;
        positions[v++] = cy;
        colors[c++] = argb;
        positions[v++] = cx + p1.dx * radius;
        positions[v++] = cy + p1.dy * radius;
        colors[c++] = argb;
        positions[v++] = cx + p2.dx * radius;
        positions[v++] = cy + p2.dy * radius;
        colors[c++] = argb;
      }
    }

    canvas.drawVertices(
      ui.Vertices.raw(ui.VertexMode.triangles, positions, colors: colors),
      BlendMode.srcOver,
      _particlePaint,
    );
  }

  @override
  void dispose() {
    _positions = null;
    _colors = null;
    super.dispose();
  }
}
