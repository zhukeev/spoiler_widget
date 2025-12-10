#include <flutter/runtime_effect.glsl>

// Improved Cloud Shader
// Uses FBM (Fractal Brownian Motion) for realistic fluffiness
// now with Elliptical masking and Discontinuous noise


uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uRect;
uniform float uSeed;
uniform vec3 uColor;   // Configurable base color
uniform float uDensity;// Configurable density
uniform float uSize;   // Configurable scale
uniform float uSpeed;  // Configurable speed

out vec4 fragColor;

// Hash for noise
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Gradient noise for smoother look
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Quintic interpolation
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// FBM with Billowy Turbulence (abs(noise))
float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    
    for (int i = 0; i < 5; i++) {
        // Billowy turbulence: abs(noise * 2 - 1) creates sharp valleys and round peaks
        // This gives the "cauliflower" or "popcorn" cloud look.
        f += amp * abs(noise(p) * 2.0 - 1.0);
        p = rot * p * 2.0 + vec2(100.0);
        amp *= 0.5;
    }
    return f;
}

void main() {
    // Current pixel coordinate in local space
    vec2 fragCoord = FlutterFragCoord().xy;
    
    // Local UVs
    vec2 localFragCoord = fragCoord - uRect.xy;
    // Uniform aspect ratio scaling logic
    vec2 noiseUV = localFragCoord / uRect.w; 
    
    // --- Discontinuous Noise ---
    vec2 seedOffset = vec2(uSeed * 13.5, uSeed * 7.1);
    
    // Animation
    float speed = uTime * 0.15; 
    
    // --- Billowy Cloud Shape ---
    // Invert billowy noise? Usually billowy noise has peaks at 1.0. 
    // We want the density to be high at peaks.
    // Lower scale (1.5) for fat features.
    vec2 p = (noiseUV * 1.5) + seedOffset - vec2(speed * 0.2, 0.0);
    
    // Domain warping (optional, but good for natural look)
    vec2 q = vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
    
    // Main density
    // We flip it: 1.0 - fbm makes the "bubbles" solid if fbm is creases.
    float f = fbm(p + q * 0.5);
    
    // Map f to density. 
    // Tighter threshold for "solid" object look (0.4 to 0.6)
    // This creates sharp edges typical of cumulus clouds.
    float density = smoothstep(0.4, 0.6, 1.0 - f); 
    
    // --- Fake Lighting / Volume ---
    // Compute normal from density gradient
    float eps = 0.01;
    // Recalculate f slightly offset (expensive but needed for volume)
    float f2 = fbm(p + q * 0.5 + vec2(eps, 0.0));
    float f3 = fbm(p + q * 0.5 + vec2(0.0, eps));
    
    // Derivative of the inverted density
    float dx = ((1.0 - f2) - (1.0 - f)) / eps;
    float dy = ((1.0 - f3) - (1.0 - f)) / eps;
    
    vec2 lightDir = normalize(vec2(-1.0, -1.0));
    float lighting = dot(vec2(dx, dy), lightDir);
    
    // --- Colors ---
    vec3 cloudColor = vec3(1.0, 1.0, 1.0);
    vec3 shadowColor = vec3(0.7, 0.75, 0.85); // Deeper, more visible shadow
    
    // Highlights
    vec3 col = mix(shadowColor, cloudColor, smoothstep(-0.2, 0.5, lighting));
    // Ambient occlusion in deep creases
    col *= smoothstep(0.0, 1.0, 1.0 - f); 

    // --- Masking ---
    // Soft Rounded Rect
    vec2 uv = localFragCoord / uResolution.xy; // 0..1 for mask
    // Rect dist: 0.45 means padding is only 0.05 on edges (very full)
    vec2 d = abs(uv - 0.5) - vec2(0.40); 
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    // Sharp falloff for mask to maximize readable area
    float mask = 1.0 - smoothstep(0.0, 0.1, dist);
    
    float alpha = density * mask;
    
    fragColor = vec4(col * alpha, alpha); // Premultiplied alpha
}
