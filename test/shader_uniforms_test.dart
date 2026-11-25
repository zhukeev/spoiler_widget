import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';

/// Counts the float slots consumed by `uniform` declarations in a GLSL
/// fragment shader. `sampler2D` uniforms use a separate index space and are
/// excluded.
int _floatUniformCount(String fragSource) {
  var count = 0;
  final pattern = RegExp(r'uniform\s+(float|vec2|vec3|vec4)\s+\w+\s*;');
  for (final match in pattern.allMatches(fragSource)) {
    count += switch (match.group(1)) {
      'float' => 1,
      'vec2' => 2,
      'vec3' => 3,
      'vec4' => 4,
      _ => 0,
    };
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Each built-in ShaderConfig must emit exactly as many floats as the
  // corresponding shader declares — otherwise uniforms shift and rendering
  // breaks silently (this is how the glitch_stripes mismatch shipped).
  final cases = <String, ShaderConfig>{
    'particles.frag': ShaderConfig.particles(),
    'bokeh_cover.frag': ShaderConfig.bokehCover(),
    'liquid_metal.frag': ShaderConfig.liquidMetal(),
    'glitch_stripes.frag': ShaderConfig.glitchStripes(),
    'mosaic_censor.frag': ShaderConfig.mosaicCensor(),
    'liquid_spectrum.frag': ShaderConfig.liquidSpectrum(),
  };

  final config = WidgetSpoilerConfig.defaultConfig();
  const rect = Rect.fromLTWH(0, 0, 100, 50);

  for (final entry in cases.entries) {
    test('ShaderConfig uniforms match ${entry.key}', () {
      final fragFile = File('shaders/${entry.key}');
      expect(fragFile.existsSync(), isTrue,
          reason: 'shader asset missing: ${entry.key}');

      final declaredFloats = _floatUniformCount(fragFile.readAsStringSync());
      final emitted = entry.value.onGetShaderUniforms!(
        rect,
        0.0,
        0.0,
        Offset.zero,
        false,
        1.0,
        config,
      );

      expect(
        emitted.length,
        declaredFloats,
        reason: '${entry.key} declares $declaredFloats float uniforms but the '
            'ShaderConfig emits ${emitted.length} values',
      );
    });
  }
}
