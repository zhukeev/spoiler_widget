#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Created by inigo quilez - iq/2013 : https://www.shadertoy.com/view/4dl3zn
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Messed up by Weyland

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

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 localFragCoord = fragCoord - uRect.xy;

  // Hard clip to the draw rect.
  if (localFragCoord.x < 0.0 || localFragCoord.y < 0.0 ||
      localFragCoord.x > uRect.z || localFragCoord.y > uRect.w) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 res = max(uResolution, vec2(1.0));
  vec2 uv = -1.0 + 2.0 * localFragCoord / res;
  uv.x *= res.x / res.y;

  // Make motion visible (original timing is extremely slow); allow speed uniform to modulate.
  float speedMul = 8.0 + uSpeed * 4.0;
  float t = uTime * speedMul;
  float seededTime = t + uSeed * 3.17;

  vec3 color = vec3(0.0);
  for (int i = 0; i < 128; i++) {
    float pha = sin(float(i) * 546.13 + 1.0) * 0.5 + 0.5;
    float siz = pow(sin(float(i) * 651.74 + 5.0) * 0.5 + 0.5, 4.0);
    float pox = sin(float(i) * 321.55 + 4.1) * res.x / res.y;
    float rad = 0.1 + 0.5 * siz + sin(pha + siz) / 4.0;
    vec2 pos = vec2(
        pox + sin(seededTime / 15.0 + pha + siz),
        -1.0 - rad + (2.0 + 2.0 * rad) *
            mod(pha + 0.3 * (seededTime / 7.0) * (0.2 + 0.8 * siz), 1.0)
    );
    float dis = length(uv - pos);
    vec3 col = mix(
        vec3(0.194 * sin(seededTime / 6.0) + 0.3, 0.2, 0.3 * pha),
        vec3(1.1 * sin(seededTime / 9.0) + 0.3, 0.2 * pha, 0.4),
        0.5 + 0.5 * sin(float(i))
    );
    float f = length(uv - pos) / rad;
    f = sqrt(clamp(1.0 + (sin((seededTime) * siz) * 0.5) * f, 0.0, 1.0));
    color += col.zyx * (1.0 - smoothstep(rad * 0.15, rad, dis));
  }

  color *= sqrt(1.5 - 0.5 * length(uv));

  // Keep extra uniforms live without altering visuals.
  float keepAlive = uResolution.x + uResolution.y +
      uRect.x + uRect.y + uRect.z + uRect.w +
      uSeed + uColor.r + uColor.g + uColor.b +
      uDensity + uSize + uSpeed +
      uFadeCenter.x + uFadeCenter.y +
      uFadeRadius + uIsFading + uEdgeThickness;
  if (keepAlive < -1.0) {
    color += keepAlive;
  }

  fragColor = vec4(color, 1.0);
}
