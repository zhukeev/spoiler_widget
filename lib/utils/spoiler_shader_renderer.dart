import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders a custom shader effect for the spoiler.
///
/// This class handles loading a user-provided fragment shader and applying it
/// to the canvas. It provides standard uniforms to the shader:
/// - uResolution (vec2)
/// - uTime (float)
/// - uRect (vec4)
/// - uSeed (float)
class SpoilerShaderRenderer {
  SpoilerShaderRenderer._({
    required ui.FragmentShader shader,
  }) : _shader = shader;

  final ui.FragmentShader _shader;

  /// Creates a new [SpoilerShaderRenderer] by loading the shader from the given path.
  ///
  /// Returns `null` if the shader asset cannot be found or loaded.
  static Future<SpoilerShaderRenderer?> create(String assetPath) async {
    try {
      final program = await ui.FragmentProgram.fromAsset(assetPath);
      final shader = program.fragmentShader();
      return SpoilerShaderRenderer._(shader: shader);
    } catch (e) {
      debugPrint('SpoilerShaderRenderer: Failed to load shader "$assetPath". Error: $e');
      return null;
    }
  }

  /// Renders the shader effect for a specific [rect].
  void render(
    Canvas canvas,
    Rect rect,
    double time, {
    required double seed,
    required List<double> params,
  }) {
    // Write all provided floats to the shader in order.
    // The CALLER (SpoilerConfig callback) is responsible for providing
    // the correct number and order of floats matching the shader.
    for (int i = 0; i < params.length; i++) {
      _shader.setFloat(i, params[i]);
    }

    final paint = Paint()..shader = _shader;
    canvas.drawRect(rect, paint);
  }

  void dispose() {
    _shader.dispose();
  }
}
