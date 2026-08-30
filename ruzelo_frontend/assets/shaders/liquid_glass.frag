#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform float uTime;
uniform float uAudioEnergy;
uniform vec3 uGlassTint;
uniform float uRefractionIndex;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    vec2 p = (uv - 0.5) * 2.0;
    p.x *= uResolution.x / uResolution.y;

    float t = uTime * 0.8;
    float len = length(p);

    // Audio-reactive fluid ripple ripples
    float wave = sin(len * 12.0 - t * 2.5) * 0.04 * (1.0 + uAudioEnergy * 1.5);
    wave += cos(p.x * 8.0 + t) * sin(p.y * 8.0 + t * 0.7) * 0.025;

    // Normal calculation for specular highlight
    vec2 normalOffset = vec2(
        sin(p.x * 10.0 + t) * 0.02,
        cos(p.y * 10.0 + t) * 0.02
    );

    // Chromatic dispersion (refracting R, G, B channels at slightly different angles)
    float disp = (0.015 + uAudioEnergy * 0.02) * uRefractionIndex;
    vec2 uvR = uv + (p + normalOffset) * (wave + disp);
    vec2 uvG = uv + (p + normalOffset) * wave;
    vec2 uvB = uv + (p + normalOffset) * (wave - disp);

    // Specular light point highlight
    vec2 lightPos = vec2(0.3 * cos(t * 0.5), 0.3 * sin(t * 0.5));
    float lightDist = length(p - lightPos);
    float specular = pow(max(1.0 - lightDist, 0.0), 16.0) * 0.45;

    // Rim lighting (Fresnel effect)
    float fresnel = pow(len * 0.7, 3.0) * 0.5;

    vec3 col = uGlassTint;
    col.r += uvR.x * 0.15 + specular;
    col.g += uvG.y * 0.15 + specular * 0.9;
    col.b += (uvB.x + uvB.y) * 0.1 + specular * 1.1 + fresnel;

    float alpha = clamp(0.25 + fresnel * 0.5 + specular, 0.1, 0.9);
    fragColor = vec4(col, alpha);
}
