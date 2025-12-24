#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// uniforms coming from Flutter
uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uRect;      // target rect we're rendering into
uniform float uSeed;      // randomization seed
uniform vec3 uColor;     // base particle color
uniform float uDensity;   // fraction of area covered (0..1)
uniform float uSize;      // particle diameter in px
uniform float uSpeed;     // speed per frame (same semantics as in Dart)

uniform vec2 uFadeCenter;
uniform float uFadeRadius;
uniform float uIsFading;
uniform float uEdgeThickness;
uniform float uEnableWaves;
uniform float uMaxWaveRadius;
uniform float uMaxWaveCount;
uniform float uShapeArea;
uniform float uUseSprite;
uniform sampler2D uParticleTex;

out vec4 fragColor;

// Fixed max to encourage loop unrolling; uMaxWaveCount clamps inside.
const int kMaxWaves = 6;
const float kWaveInvDuration = 0.33333334; // 1/3 sec^-1 => 3s cycles
const float kLifeFloor = 0.0;
const float kLifeSizeMin = 0.6;

// ---------- Utils ----------

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

// simple hash for pseudo-random values per cell
vec2 hash2(vec2 p) {
    // works better across mobile GPUs
    vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// cheap smoothstep band around wavefront (0..1 peak at front)
float waveFrontBand(float dist, float radius, float bandPx) {
    float d = abs(dist - radius);
    return 1.0 - smoothstep(0.0, bandPx, d);
}

float sdCircle(vec2 p) {
    return length(p) - 1.0;
}

void main() {
    // pixel coordinate in screen space
    vec2 fragCoord = FlutterFragCoord().xy;

    // convert to local coordinates inside provided rect
    vec2 localFragCoord = fragCoord - uRect.xy;

    // hard clip — exactly like Canvas clipRect
    if(localFragCoord.x < 0.0 || localFragCoord.y < 0.0 ||
        localFragCoord.x > uRect.z || localFragCoord.y > uRect.w) {
        fragColor = vec4(0.0);
        return;
    }

    // base radius derived from particle size
    float baseRadiusPx = max(uSize * 0.5, 0.5);
    float boundaryFadePx = max(baseRadiusPx * 3.0, 6.0);
    float density = clamp(uDensity, 0.0, 1.0);
    if(density <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float shapeAreaFactor = max(uShapeArea, 0.0001);

    // compute grid cell spacing from density
    float particleArea = 3.14159265 * baseRadiusPx * baseRadiusPx * shapeAreaFactor;
    float safeDensity = max(density / max(particleArea, 0.0001), 0.000001);
    float cellSpacing = sqrt(1.0 / safeDensity);

    // find which cell this fragment belongs to
    vec2 cellCoord = localFragCoord / cellSpacing;
    vec2 gridID = floor(cellCoord);

    // lifetime / movement parameters — intentionally matched with the CPU version
    float fps = 60.0;
    float lifetimeSec = 2.6;
    float speedPxFrame = (uSpeed > 0.0) ? uSpeed : 0.2;
    speedPxFrame *= 0.5; // visual match with Canvas

    // accumulators for src-over blend model
    vec3 colorAccum = vec3(0.0);
    float alphaAccum = 0.0;

    // Fade setup
    vec2 fadeCenterLocal = uFadeCenter - uRect.xy;
    bool fading = (uIsFading > 0.5) && (uFadeRadius > 0.0001);

    float fadeRadiusSq = uFadeRadius * uFadeRadius;
    float innerFadeRadius = max(uFadeRadius - max(uEdgeThickness, 0.0), 0.0);
    float innerFadeRadiusSq = innerFadeRadius * innerFadeRadius;

    vec2 rectSize = uRect.zw;
    float minDim = min(rectSize.x, rectSize.y);

    float waveCount = clamp(uMaxWaveCount, 0.0, float(kMaxWaves));
    bool wavesEnabled = (uEnableWaves > 0.5) && (waveCount > 0.5);

    // Wave feel tuning (keep cheap)
    const float kWaveLimitOffset = 25.0;
    const float kPushScale = 0.46;  // stronger displacement but still avoids "hole"
    const float kFrontBandPx = 28.0;  // thicker sparkle band
    const float kFrontBoostSize = 1.38;
    const float kFrontBoostBri = 2.80;
    const float kEdgeBoostBri = 2.1;

    // sample 3x3 neighbor cells — each may contribute one particle
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {

            vec2 neighbor = vec2(float(x), float(y));
            vec2 cellID = gridID + neighbor;

            // random values per cell (stable across frames)
            vec2 rndPhase = hash2(cellID + vec2(uSeed));

            // pick a direction angle for this particle (no trig)
            vec2 dirSeed = hash2(cellID + uSeed + 13.37) * 2.0 - 1.0;
            float dirInvLen = inversesqrt(max(dot(dirSeed, dirSeed), 0.0001));
            vec2 vel = dirSeed * dirInvLen;

            // --- life cycle & motion ---
            float phaseSec = rndPhase.y * lifetimeSec;
            float tShifted = uTime + phaseSec;
            float cycleIdx = floor(tShifted / lifetimeSec);
            float timeInCycle = tShifted - cycleIdx * lifetimeSec;
            float life = 1.0 - timeInCycle / lifetimeSec;
            float lifeAlpha = mix(kLifeFloor, 1.0, life);

            // base spawn position inside this cell (changes per cycle)
            vec2 rndPos = hash2(cellID + vec2(uSeed) + cycleIdx * 17.13);
            vec2 basePosPx = (cellID + rndPos) * cellSpacing;

            float displacementPx = speedPxFrame * fps * timeInCycle;
            vec2 particlePosPx = basePosPx + vel * displacementPx;

            // per-particle stable randoms
            float rndBri = hash2(cellID + uSeed + 201.700).x;

            float frontPop = 0.0;

            if(wavesEnabled) {
                // Only a subset gets pushed (tune threshold).
                float affect = step(0.70, rndBri); // ~30% affected

                if(affect > 0.5) {
                    for(int i = 0; i < kMaxWaves; i++) {
                        if(float(i) >= waveCount)
                            break;

                        float timeOffset = float(i) * 1.23;
                        float globalTime = uTime + timeOffset;

                        float cycleIdx = floor(globalTime * kWaveInvDuration);
                        float progress = fract(globalTime * kWaveInvDuration);

                        // IMPORTANT: keep vec2 math (avoid vec2+float surprises)
                        vec2 seed2 = vec2(uSeed);
                        vec2 waveSeed = vec2(float(i), cycleIdx) + seed2;

                        vec2 waveRnd = hash2(waveSeed * 13.57);

                        // Bias centers toward middle so effect is visible more often
                        vec2 waveCenter = (waveRnd * 0.70 + 0.15) * rectSize;

                        float randomMaxRadius = (0.30 + 0.45 * waveRnd.y) * minDim;
                        float maxRadius = (uMaxWaveRadius > 0.0) ? uMaxWaveRadius : randomMaxRadius;

                        float currentRadius = (maxRadius + kWaveLimitOffset) * progress;
                        float currentRadiusSq = currentRadius * currentRadius;

                        vec2 distVec = particlePosPx - waveCenter;
                        float distSq = dot(distVec, distVec);

                        // inside => push outward
                        if(distSq < currentRadiusSq) {
                            float invDist = inversesqrt(max(distSq, 0.0001));
                            vec2 direction = distVec * invDist;
                            float dist = 1.0 / invDist;

                            // 0 at front, 1 at center (but not too aggressive)
                            float ratio = dist / max(currentRadius, 0.0001);
                            float deep = saturate(1.0 - ratio);

                            // softer than pow8: deep^2 * (0.75 + 0.25*deep)
                            float deepShape = deep * deep * (0.75 + 0.25 * deep);

                            // push proportional to remaining distance to front
                            float remain = currentRadius - dist;

                            // fade out at end of cycle (like you did)
                            float fadeOut = 1.0 - smoothstep(0.72, 1.0, progress);

                            float displacement = remain * deepShape * kPushScale * fadeOut;

                            // apply
                            particlePosPx += direction * displacement;

                            // compute front pop too
                            float fp = waveFrontBand(dist, currentRadius, kFrontBandPx) * fadeOut;
                            frontPop = max(frontPop, fp);
                        }
                    }
                }
            }

            // ---------------- Fade edge band (match canvas: hard edge) ----------------
            float edgeBand = 0.0;
            float fadeMask = 1.0;

            if(fading) {
                vec2 toFade = particlePosPx - fadeCenterLocal;
                float distSqF = dot(toFade, toFade);

                if(distSqF > fadeRadiusSq) {
                    fadeMask = 0.0;
                } else if(distSqF > innerFadeRadiusSq) {
                    // hard band in [inner..outer]
                    edgeBand = 1.0;
                }
            }

            float edgeDist = min(min(particlePosPx.x, particlePosPx.y), min(rectSize.x - particlePosPx.x, rectSize.y - particlePosPx.y));
            float edgeFade = smoothstep(0.0, boundaryFadePx, edgeDist);

            float bandScale = mix(1.0, 1.5, edgeBand);
            float lifeScale = mix(kLifeSizeMin, 1.0, life);
            float particleRadiusPx = baseRadiusPx * bandScale * lifeScale;

            float edgeClamp = clamp(edgeDist / max(particleRadiusPx, 0.0001), 0.0, 1.0);
            float edgeScale = mix(0.35, 1.0, edgeFade) * edgeClamp;
            particleRadiusPx *= edgeScale;

            float alphaLife = mix(lifeAlpha, 1.0, edgeBand) * edgeFade * edgeClamp;
            if(alphaLife <= 0.0001) {
                continue;
            }

            if(fadeMask > 0.5) {
                // front sparkle: make some particles pop near front, but not perfect ring
                float sparkle = 0.0;
                if(wavesEnabled && frontPop > 0.0) {
                    // selective mask + spatial noise to avoid a clean circle
                    float mask = step(0.50, rndBri);
                    float n = hash2(localFragCoord * 0.45 + uSeed).x;
                    sparkle = frontPop * mask * smoothstep(0.15, 0.95, n);
                }

                // sparkle changes feel: prefer alpha over size (Telegram)
                particleRadiusPx *= mix(1.0, kFrontBoostSize, sparkle);

                // compute shape SDF around this particle
                vec2 diffPx = localFragCoord - particlePosPx;
                float intensity = 0.0;

                if(uUseSprite > 0.5) {
                    float invDiameter = 1.0 / max(particleRadiusPx * 2.0, 0.0001);
                    vec2 uv = diffPx * invDiameter + 0.5;
                    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                        continue;
                    }
                    intensity = texture(uParticleTex, uv).a;
                } else {
                    vec2 p = diffPx / max(particleRadiusPx, 0.0001);
                    float distPx = sdCircle(p) * particleRadiusPx;

                    float aaPx = max(0.5, particleRadiusPx * 0.5);
                    intensity = 1.0 - smoothstep(0.0, aaPx, distPx);
                }

                float candidateAlpha = intensity * alphaLife;
                candidateAlpha *= mix(1.0, kFrontBoostBri, sparkle);
                candidateAlpha *= mix(1.0, kEdgeBoostBri, edgeBand);

                // color: base, and edge band tends to white (like your old behavior)
                vec3 particleColor = mix(uColor, vec3(1.0), edgeBand);

                // apply color into src-over
                vec3 src = particleColor;

                // classic src-over alpha blending
                colorAccum = colorAccum + src * candidateAlpha * (1.0 - alphaAccum);
                alphaAccum = alphaAccum + candidateAlpha * (1.0 - alphaAccum);
            }
        }
    }

    float alpha = clamp(alphaAccum, 0.0, 1.0);

    // prevent compiler dropping uniform
    float resSum = uResolution.x + uResolution.y;
    float resMultiplier = step(0.0, resSum);

    alpha *= resMultiplier;
    colorAccum *= resMultiplier;

    fragColor = vec4(colorAccum, alpha);
}
