#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Liquid Spectrum — HSV-driven FBM with cycling time.

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

float ltime;

float noise(vec2 p) {
  return sin(p.x * 10.0) * sin(p.y * (3.0 + sin(ltime / 11.0))) + 0.2;
}

mat2 rotate(float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return mat2(c, -s, s, c);
}

float fbm(vec2 p) {
  p *= 1.1;
  float f = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 3; i++) {
    mat2 modify = rotate(ltime / 50.0 * float(i * i));
    f += amp * noise(p);
    p = modify * p;
    p *= 2.0;
    amp /= 2.2;
  }
  return f;
}

float pattern(vec2 p, out vec2 q, out vec2 r) {
  q = vec2(
    fbm(p + vec2(1.0)),
    fbm(rotate(0.1 * ltime) * p + vec2(3.0))
  );
  r = vec2(
    fbm(rotate(0.2) * q + vec2(0.0)),
    fbm(q + vec2(0.0))
  );
  return fbm(p + 1.0 * r);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 local = fragCoord - uRect.xy;
  if (local.x < 0.0 || local.y < 0.0 || local.x > uRect.z || local.y > uRect.w) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 res = max(uRect.zw, vec2(1.0));
  float minDim = max(min(res.x, res.y), 1.0);

  // Aspect-correct UV and zoom out on small rects to avoid squashing.
  vec2 p = local / res;
  p.x *= res.x / res.y;
  float zoom = mix(0.6, 1.0, clamp(minDim / 300.0, 0.0, 1.0));
  p *= zoom;

  float timeScale = 1.0 + uSpeed * 2.0;
  float baseTime = uTime * timeScale + uSeed * 0.5;
  ltime = baseTime;
  float ctime = baseTime + fbm(p / 8.0) * 40.0;
  float ftime = fract(ctime / 6.0);
  ltime = floor(ctime / 6.0) + (1.0 - cos(ftime * 3.1415) / 2.0);
  ltime = ltime * 6.0;

  vec2 q;
  vec2 r;
  float f = pattern(p, q, r);
  vec3 spectrum = hsv2rgb(vec3(q.x / 10.0 + ltime / 100.0 + 0.4, abs(r.y) * 3.0 + 0.1, r.x + f));
  vec3 col = mix(uColor, spectrum, 0.8);

  // Vignette based on local coords.
  float vigX = 1.0 - pow(4.0 * (p.x - 0.5) * (p.x - 0.5), 10.0);
  float vigY = 1.0 - pow(4.0 * (p.y - 0.5) * (p.y - 0.5), 10.0);
  float vig = vigX * vigY;
  col *= vig;

  float alpha = 1.0;

  // Keep fade uniforms live; avoid cutting alpha (clipping handled by renderer).
  float ring = 1.0;
  if (uIsFading > 0.5 && uFadeRadius > 0.0001) {
    vec2 fadeCenterLocal = uFadeCenter - uRect.xy;
    float dist = length(local - fadeCenterLocal);
    float maxR = length(uRect.zw);
    float r = min(uFadeRadius, maxR);
    ring = smoothstep(r - uEdgeThickness, r, dist);
    col = mix(col, col * 1.08, ring * 0.2);
  }

  // Edge softening.
  float pad = max(uEdgeThickness, 1.0);
  vec2 edgeIn = smoothstep(vec2(0.0), vec2(pad), local);
  vec2 edgeOut = smoothstep(vec2(0.0), vec2(pad), uRect.zw - local);
  float edgeMask = min(min(edgeIn.x, edgeIn.y), min(edgeOut.x, edgeOut.y));
  alpha *= edgeMask;
  col *= edgeMask;

  // Keep all uniforms live.
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
