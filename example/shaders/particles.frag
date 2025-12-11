#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// uniforms coming from Flutter
uniform vec2  uResolution;
uniform float uTime;
uniform vec4  uRect;      // target rect we're rendering into
uniform float uSeed;      // randomization seed
uniform vec3  uColor;     // base particle color
uniform float uDensity;   // number of particles per area
uniform float uSize;      // particle diameter in px
uniform float uSpeed;     // speed per frame (same semantics as in Dart)

uniform vec2  uFadeCenter;
uniform float uFadeRadius;
uniform float uIsFading;
uniform float uEdgeThickness;

out vec4 fragColor;

// simple hash for pseudo-random values per cell
vec2 hash2(vec2 p) {
    p = vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    );
    return fract(sin(p) * 43758.5453);
}

void main() {
    // pixel coordinate in screen space
    vec2 fragCoord = FlutterFragCoord().xy;

    // convert to local coordinates inside provided rect
    vec2 localFragCoord = fragCoord - uRect.xy;

    // hard clip — exactly like Canvas clipRect
    if (localFragCoord.x < 0.0 || localFragCoord.y < 0.0 ||
        localFragCoord.x > uRect.z || localFragCoord.y > uRect.w) {
        fragColor = vec4(0.0);
        return;
    }

    // compute grid cell spacing from density (more density → smaller cells)
    float safeDensity = max(uDensity, 0.0001);
    float cellSpacing = sqrt(1.0 / safeDensity);

    // find which cell this fragment belongs to
    vec2 cellCoord = localFragCoord / cellSpacing;
    vec2 gridID    = floor(cellCoord);

    // base radius derived from particle size; 
    // keep a very small floor to avoid disappearing on tiny values
    float particleRadiusPx = max(uSize * 0.5, 0.5);
    float aaPx = max(0.75, particleRadiusPx * 0.5);

    // lifetime / movement parameters — intentionally matched with the CPU version
    float fps          = 60.0;
    float lifetimeSec  = 1.5; 
    float speedPxFrame = (uSpeed > 0.0) ? uSpeed : 0.2;

    // halving speed to visually match the Canvas motion characteristics
    speedPxFrame *= 0.5;

    // will accumulate alpha via a src-over blend model
    float alphaAccum = 0.0;
    float edgeAlphaAccum = 0.0; // tracks contribution of edge-boosted particles for white tinting

    // Per-pixel edge factor (band near the fade radius)
    float edgeFactorPx = 0.0;
    if (uIsFading > 0.5 && uFadeRadius > 0.0001) {
        vec2 fadeCenterLocal = uFadeCenter - uRect.xy;
        float distToCenter   = length(localFragCoord - fadeCenterLocal);
        if (distToCenter <= uFadeRadius && uEdgeThickness > 0.0) {
            edgeFactorPx = smoothstep(
                uFadeRadius - uEdgeThickness,
                uFadeRadius,
                distToCenter
            );
        }
    }

    // sample 3x3 neighbor cells — each may contribute one particle
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {

            vec2 neighbor = vec2(float(x), float(y));
            vec2 cellID   = gridID + neighbor;

            // random values per cell (stable across frames)
            vec2 rnd = hash2(cellID + uSeed);

            // pick a direction angle for this particle
            float cycleHash = hash2(cellID + uSeed + 13.37).x;
            float angle = cycleHash * 6.2831853;
            vec2  vel   = vec2(cos(angle), sin(angle));

            // base spawn position inside this cell
            vec2 basePosPx = (cellID + rnd) * cellSpacing;

            // --- life cycle & motion ---
            // slightly desync particles inside cells so they don’t pulse in unison
            float phaseSec    = rnd.y * lifetimeSec;
            float tShifted    = uTime + phaseSec;

            // how far this particle is into its life cycle (0..lifetimeSec)
            float timeInCycle = mod(tShifted, lifetimeSec);

            // normalized life (1 → newborn, 0 → dying)
            float life = 1.0 - timeInCycle / lifetimeSec;

            // same movement equation you use on the CPU: speed * frames * time
            float displacementPx = speedPxFrame * fps * timeInCycle;

            // actual particle position
            vec2 particlePosPx = basePosPx + vel * displacementPx;

            // particles near "death" become invisible and will respawn
            float visible   = step(0.1, life);
            float alphaLife = life * visible;
            // ---------------------------

            // --- visual “dustiness” ---
            // dying particles appear smaller; newborn ones appear larger
            float lifeScale = mix(0.4, 1.0, life);

            // subtle per-particle random jitter to break uniform look
            float randSize     = hash2(cellID + uSeed + 99.123).x;
            float jitterScale  = mix(0.8, 1.2, randSize);

            // final radius for this particle instance
            float particleRadiusPx = max(uSize * 0.5, 0.5) * lifeScale * jitterScale;

            particleRadiusPx *= mix(1.0, 1.5, edgeFactorPx);

            // AA proportional to particle size
            float aaPx = max(0.5, particleRadiusPx * 0.5);

            // compute distance of this pixel from the particle’s center
            vec2  diffPx = particlePosPx - localFragCoord;
            float distPx = length(diffPx);

            // soft-ish disk; visually closer to the rawAtlas circle texture
            float intensity = 1.0 - smoothstep(
                particleRadiusPx - aaPx,
                particleRadiusPx + aaPx,
                distPx
            );

            // this particle’s opacity contribution
            float candidateAlpha = intensity * alphaLife;
            // Boost alpha near fade edge
            float alphaBoost = mix(1.0, 1.5, edgeFactorPx);
            candidateAlpha *= alphaBoost;

            // classic src-over alpha blending (same behavior Canvas uses)
            alphaAccum = alphaAccum + candidateAlpha * (1.0 - alphaAccum);

            // Track edge-weighted alpha separately for white tint mix later
            float edgeAlpha = candidateAlpha * edgeFactorPx;
            edgeAlphaAccum = edgeAlphaAccum + edgeAlpha * (1.0 - edgeAlphaAccum);
        }
    }

    // final color modulated by accumulated alpha
    float alpha = clamp(alphaAccum, 0.0, 1.0);
    vec3  col   = uColor * alpha;

    // Fade edge highlight: tint only where edge-boosted particles contributed.
    if (uIsFading > 0.5 && uFadeRadius > 0.0001 && alpha > 0.0) {
        float edgeMix = clamp(edgeAlphaAccum / alpha, 0.0, 1.0);
        col = mix(col, vec3(1.0) * alpha, edgeMix * 0.6);
    }

    // small trick so compiler doesn’t drop this uniform
    float resSum        = uResolution.x + uResolution.y;
    float resMultiplier = step(0.0, resSum);

    alpha *= resMultiplier;

    fragColor = vec4(col, alpha);
}