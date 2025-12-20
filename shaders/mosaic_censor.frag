#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Pixelated censor blocks. Block size driven by uSize/uDensity; fades open.

uniform vec2  uResolution;
uniform float uTime;
uniform vec4  uRect;
uniform float uSeed;
uniform vec3  uColor;
uniform float uDensity;
uniform float uSize;
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

  float block = mix(6.0, 32.0, clamp(uSize * 0.2 + uDensity, 0.0, 1.0));
  vec2 id = floor(local / block);

  float t = uTime * (0.25 + uSpeed * 1.5);
  float rnd = hash21(id + uSeed + floor(t));
  vec3 col = mix(uColor, vec3(0.15, 0.16, 0.18), 0.35 + 0.35 * rnd);

  // Slight wobble to avoid perfect grid lock.
  vec2 wobble = (vec2(hash21(id + 7.7), hash21(id + 13.7)) - 0.5) * block * 0.12;
  local += wobble;

  float alpha = 1.0;

  // Fade hole effect.
  if (uFadeRadius > 0.0001) {
    vec2 fadeCenterLocal = uFadeCenter - uRect.xy;
    float dist = length(local - fadeCenterLocal);
    float ring = smoothstep(uFadeRadius - uEdgeThickness, uFadeRadius, dist);
    alpha *= ring;
  }

  // Edge soften.
  float pad = max(uEdgeThickness, 1.0);
  vec2 edgeIn = smoothstep(vec2(0.0), vec2(pad), local);
  vec2 edgeOut = smoothstep(vec2(0.0), vec2(pad), uRect.zw - local);
  float edgeMask = min(min(edgeIn.x, edgeIn.y), min(edgeOut.x, edgeOut.y));
  alpha *= edgeMask;

  float keepAlive = uResolution.x + uResolution.y +
      uRect.x + uRect.y + uRect.z + uRect.w +
      uSeed + uColor.r + uColor.g + uColor.b +
      uDensity + uSize + uSpeed +
      uFadeCenter.x + uFadeCenter.y +
      uFadeRadius + uIsFading + uEdgeThickness;
  if (keepAlive < -1.0) {
    col += keepAlive;
  }

  fragColor = vec4(col, alpha);
}
