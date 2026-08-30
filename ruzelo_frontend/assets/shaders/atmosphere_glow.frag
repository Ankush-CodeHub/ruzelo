#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform float uAudioEnergy;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uColorC;
uniform vec3 uColorD;

out vec4 fragColor;

// Simplex 2D noise helper functions
vec3 permute(vec3 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
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

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < 4; i++) {
        value += amplitude * snoise(st * frequency);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    vec2 st = uv;
    st.x *= uResolution.x / uResolution.y;

    float t = uTime * 0.12;
    float audioBoost = 1.0 + (uAudioEnergy * 0.85);

    // Multi-octave domain warping
    vec2 q = vec2(
        fbm(st + vec2(t * 0.4, t * 0.2)),
        fbm(st + vec2(t * 0.3, -t * 0.5))
    );

    vec2 r = vec2(
        fbm(st + (q * 1.6) + vec2(t * 0.6, t * 0.3) * audioBoost),
        fbm(st + (q * 1.6) + vec2(-t * 0.4, t * 0.7) * audioBoost)
    );

    float f = fbm(st + (r * 2.0));

    // Multi-gradient interpolation across 4 dynamic colors
    float mix1 = clamp((f * 0.5 + 0.5) + (q.x * 0.25), 0.0, 1.0);
    float mix2 = clamp((r.y * 0.5 + 0.5) + (uAudioEnergy * 0.3), 0.0, 1.0);
    float mix3 = clamp((r.x * 0.5 + 0.5) * (q.y * 0.5 + 0.5), 0.0, 1.0);

    vec3 col = mix(uColorA, uColorB, mix1);
    col = mix(col, uColorC, mix2 * 0.75);
    col = mix(col, uColorD, mix3 * 0.5);

    // Radial vignette and deep obsidian floor blend
    vec2 centerDist = uv - vec2(0.5, 0.5);
    float distSq = dot(centerDist, centerDist);
    float vignette = clamp(1.0 - distSq * 1.4, 0.2, 1.0);
    col *= vignette;

    fragColor = vec4(col, 1.0);
}
