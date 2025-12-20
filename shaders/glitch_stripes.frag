#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Glitchy horizontal stripes with RGB splits.
uniform vec2  uResolution;
uniform float uTime;
uniform vec4  uRect;
uniform float uSeed;
uniform vec3  uColor;
uniform float uDensity;
uniform float uSpeed;
uniform vec2  uFadeCenter;
uniform float uFadeRadius;
uniform float uIsFading;
uniform float uEdgeThickness;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(234.34, 435.345));
  p += dot(p, p + 34.45);
  return fract(p.x * p.y);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 local = fragCoord - uRect.xy;
  if (local.x < 0.0 || local.y < 0.0 || local.x > uRect.z || local.y > uRect.w) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 res = max(uResolution, vec2(1.0));
  float speed = 0.6 + uSpeed * 2.5;
  float stripeH = mix(5.0, 18.0, clamp(uDensity, 0.0, 1.0));
  float yIdx = floor(local.y / stripeH);

  float t = uTime * speed;
  float rowRnd = hash21(vec2(yIdx, floor(t)));
  float shift = (rowRnd - 0.5) * 18.0;

  // Horizontal UV with jitter and small vertical warps for glitchiness.
  vec2 uv = (local + vec2(shift, 0.0)) / uRect.zw;
  float warp = (hash21(vec2(yIdx, yIdx + 3.1)) - 0.5) * 0.02;
  uv.y += sin(t * 5.0 + yIdx * 0.5) * warp;

  vec3 base = uColor;
  vec3 col = vec3(
      base.r,
      base.g + 0.15 * sin(t * 2.0 + rowRnd * 3.7),
      base.b + 0.15 * cos(t * 1.6 + rowRnd * 2.9)
  );

  // RGB split
  float bandMask = smoothstep(0.15, 0.95, fract(uv.y * 40.0 + rowRnd * 3.0));
  float alpha = bandMask;

  vec3 split = vec3(
    col.r,
    col.g * (0.8 + 0.2 * sin(t + rowRnd * 1.7)),
    col.b * (0.8 + 0.2 * cos(t + rowRnd * 2.3))
  );

  // Periodic blanks for more glitchiness.
  float blank = step(0.9, fract(t * 0.8 + rowRnd * 2.0));
  alpha *= mix(1.0, 0.0, blank);

  // Base coverage so overlay is never fully transparent.
  float baseAlpha = 0.6;
  alpha = max(alpha, baseAlpha);
  col = mix(uColor, split, 0.7);

  // Edge softening.
  float pad = max(uEdgeThickness, 1.0);
  vec2 edgeIn = smoothstep(vec2(0.0), vec2(pad), local);
  vec2 edgeOut = smoothstep(vec2(0.0), vec2(pad), uRect.zw - local);
  float edgeMask = min(min(edgeIn.x, edgeIn.y), min(edgeOut.x, edgeOut.y));
  alpha *= edgeMask;

  // Keep fade uniforms live but avoid cutting alpha (clipping handled by Dart).
  float ring = 1.0;
  if (uIsFading > 0.5 && uFadeRadius > 0.0001) {
    vec2 fadeCenterLocal = uFadeCenter - uRect.xy;
    float dist = length(local - fadeCenterLocal);
    float maxR = length(uRect.zw);
    float r = min(uFadeRadius, maxR);
    ring = smoothstep(r - uEdgeThickness, r, dist);
    col = mix(col, col * 1.05, ring * 0.2);
  }

  // Grain for style.
  float grain = hash21(local / stripeH + t * 0.2) * 0.12;

  col = split * alpha + grain;

  // Keep all uniforms live to match uniform layout.
  float keepAlive = uResolution.x + uResolution.y +
      uRect.x + uRect.y + uRect.z + uRect.w +
      uSeed + uColor.r + uColor.g + uColor.b +
      uDensity + uSpeed +
      uFadeCenter.x + uFadeCenter.y +
      uFadeRadius + uIsFading + uEdgeThickness;
  if (keepAlive < -1.0) {
    col += keepAlive;
  }

  fragColor = vec4(col, alpha);
}
