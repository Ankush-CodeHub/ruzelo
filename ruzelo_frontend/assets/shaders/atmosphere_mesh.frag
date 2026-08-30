#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform float uAudioEnergy;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uColorC;

out vec4 fragColor;

// Simplex 2D noise helper functions
vec3 permute(vec3 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                   + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy),
                            dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

void main() {
    vec2 st = FlutterFragCoord().xy / uResolution.xy;
    st.x *= uResolution.x / uResolution.y;

    float t = uTime * 0.15;
    float audioBoost = 1.0 + (uAudioEnergy * 0.75);

    // Multi-layered fluid domain warping
    vec2 q = vec2(
        snoise(st * 1.2 + vec2(t * 0.5, t * 0.3)),
        snoise(st * 1.2 + vec2(t * 0.4, -t * 0.6))
    );

    vec2 r = vec2(
        snoise(st * 2.0 + q * 1.5 + vec2(t * 0.7, t * 0.2) * audioBoost),
        snoise(st * 2.0 + q * 1.5 + vec2(-t * 0.3, t * 0.8) * audioBoost)
    );

    float f = snoise(st * 1.8 + r * 2.2);

    // Color gradient mapping
    float mixVal1 = clamp((f * 0.5 + 0.5) + (q.x * 0.3), 0.0, 1.0);
    float mixVal2 = clamp((r.y * 0.5 + 0.5) + (uAudioEnergy * 0.2), 0.0, 1.0);

    vec3 col = mix(uColorA, uColorB, mixVal1);
    col = mix(col, uColorC, mixVal2 * 0.8);

    // Vignette and subtle glow attenuation
    vec2 centerDist = (FlutterFragCoord().xy / uResolution.xy) - vec2(0.5);
    float vignette = 1.0 - dot(centerDist, centerDist) * 1.35;
    col *= clamp(vignette, 0.25, 1.0);

    fragColor = vec4(col, 1.0);
}
