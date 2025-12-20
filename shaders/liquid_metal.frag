#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Licence CC0: Liquid Metal

#define PI  3.141592654
#define TAU (2.0 * PI)

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

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
}

float hash(vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 58.233))) * 13758.5453);
}

vec2 hash2(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return fract(sin(p) * 18.5453);
}

float psin(float a) {
  return 0.5 + 0.5 * sin(a);
}

float tanh_approx(float x) {
  float x2 = x * x;
  return clamp(x * (27.0 + x2) / (27.0 + 9.0 * x2), -1.0, 1.0);
}

float onoise(vec2 x) {
  x *= 0.5;
  float a = sin(x.x);
  float b = sin(x.y);
  float c = mix(a, b, psin(TAU * tanh_approx(a * b + a + b)));
  return c;
}

float vnoise(vec2 x) {
  vec2 i = floor(x);
  vec2 w = fract(x);

  vec2 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

  float a = hash(i + vec2(0.0, 0.0));
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  float k0 = a;
  float k1 = b - a;
  float k2 = c - a;
  float k3 = d - c + a - b;

  float aa = mix(a, b, u.x);
  float bb = mix(c, d, u.x);
  float cc = mix(aa, bb, u.y);

  return k0 + k1 * u.x + k2 * u.y + k3 * u.x * u.y;
}

float fbm1(vec2 p) {
  vec2 op = p;
  const float aa = 0.45;
  const float pp = 2.03;
  const vec2 oo = -vec2(1.23, 1.5);
  const float rr = 1.2;

  float h = 0.0;
  float d = 0.0;
  float a = 1.0;

  for (int i = 0; i < 5; ++i) {
    h += a * onoise(p);
    d += a;
    a *= aa;
    p += oo;
    p *= pp;
    rot(p, rr);
  }

  return mix((h / d), -0.5 * (h / d), pow(vnoise(0.9 * op), 0.25));
}

float fbm2(vec2 p) {
  vec2 op = p;
  const float aa = 0.45;
  const float pp = 2.03;
  const vec2 oo = -vec2(1.23, 1.5);
  const float rr = 1.2;

  float h = 0.0;
  float d = 0.0;
  float a = 1.0;

  for (int i = 0; i < 7; ++i) {
    h += a * onoise(p);
    d += a;
    a *= aa;
    p += oo;
    p *= pp;
    rot(p, rr);
  }

  return mix((h / d), -0.5 * (h / d), pow(vnoise(0.9 * op), 0.25));
}

float fbm3(vec2 p) {
  vec2 op = p;
  const float aa = 0.45;
  const float pp = 2.03;
  const vec2 oo = -vec2(1.23, 1.5);
  const float rr = 1.2;

  float h = 0.0;
  float d = 0.0;
  float a = 1.0;

  for (int i = 0; i < 3; ++i) {
    h += a * onoise(p);
    d += a;
    a *= aa;
    p += oo;
    p *= pp;
    rot(p, rr);
  }

  return mix((h / d), -0.5 * (h / d), pow(vnoise(0.9 * op), 0.25));
}

float warp(vec2 p, float time) {
  vec2 v = vec2(fbm1(p), fbm1(p + 0.7 * vec2(1.0, 1.0)));

  rot(v, 1.0 + time * 1.8);

  vec2 vv = vec2(
      fbm2(p + 3.7 * v),
      fbm2(p + -2.7 * v.yx + 0.7 * vec2(1.0, 1.0)));

  rot(vv, -1.0 + time * 0.8);

  return fbm3(p + 9.0 * vv);
}

float height(vec2 p, float time) {
  float a = 0.045 * time;
  p += 9.0 * vec2(cos(a), sin(a));
  p *= 2.0;
  p += 13.0;
  float h = warp(p, time);
  float rs = 3.0;
  return 0.35 * tanh_approx(rs * h) / rs;
}

vec3 normal(vec2 p, float time) {
  vec2 eps = -vec2(2.0 / uResolution.y, 0.0);

  vec3 n;
  n.x = height(p + eps.xy, time) - height(p - eps.xy, time);
  n.y = 2.0 * eps.x;
  n.z = height(p + eps.yx, time) - height(p - eps.yx, time);

  return normalize(n);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 localFragCoord = fragCoord - uRect.xy;

  if (localFragCoord.x < 0.0 || localFragCoord.y < 0.0 ||
      localFragCoord.x > uRect.z || localFragCoord.y > uRect.w) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 res = max(uResolution, vec2(1.0));
  vec2 q = localFragCoord / res;
  vec2 p = -1.0 + 2.0 * q;
  p.x *= res.x / res.y;

  // Time scaling influenced by speed uniform.
  float time = uTime * (1.0 + uSpeed * 3.0);

  const vec3 lp1 = vec3(2.1, -0.5, -0.1);
  const vec3 lp2 = vec3(-2.1, -0.5, -0.1);

  float h = height(p, time);
  vec3 pp = vec3(p.x, h, p.y);
  float ll1 = length(lp1.xz - pp.xz);
  vec3 ld1 = normalize(lp1 - pp);
  vec3 ld2 = normalize(lp2 - pp);

  vec3 n = normal(p, time);
  float diff1 = max(dot(ld1, n), 0.0);
  float diff2 = max(dot(ld2, n), 0.0);

  vec3 baseCol1 = vec3(0.5, 0.4, 0.4);
  vec3 baseCol2 = vec3(0.1, 0.1, 0.1);

  float oh = height(p + ll1 * 0.05 * normalize(ld1.xz), time);
  const float level0 = 0.0;
  const float level1 = 0.125;

  vec3 scol1 = baseCol1 * (smoothstep(level0, level1, h) - smoothstep(level0, level1, oh));
  vec3 scol2 = baseCol2 * (smoothstep(level0, level1, h) - smoothstep(level0, level1, oh));

  vec3 col = vec3(0.0);
  col += 0.55 * baseCol1.zyx * pow(diff1, 1.0);
  col += 0.55 * baseCol1.zyx * pow(diff1, 1.0);
  col += 0.55 * baseCol2.zyx * pow(diff2, 1.0);
  col += 0.55 * baseCol2.zyx * pow(diff2, 1.0);
  col += scol1 * 0.5;
  col += scol2 * 0.5;

  // Slight tint blend with user color.
  col = mix(col, uColor, 0.25);

  // Soft edge padding to avoid hard borders.
  float pad = max(uEdgeThickness, 1.0);
  vec2 edgeIn = smoothstep(vec2(0.0), vec2(pad), localFragCoord);
  vec2 edgeOut = smoothstep(vec2(0.0), vec2(pad), uRect.zw - localFragCoord);
  float edgeMask = min(min(edgeIn.x, edgeIn.y), min(edgeOut.x, edgeOut.y));
  col *= edgeMask;

  // Keep extra uniforms live without affecting visuals.
  float keepAlive = uResolution.x + uResolution.y +
      uRect.x + uRect.y + uRect.z + uRect.w +
      uSeed + uColor.r + uColor.g + uColor.b +
      uDensity + uSize + uSpeed +
      uFadeCenter.x + uFadeCenter.y +
      uFadeRadius + uIsFading + uEdgeThickness;
  if (keepAlive < -1.0) {
    col += keepAlive;
  }

  fragColor = vec4(col, 1.0);
}
