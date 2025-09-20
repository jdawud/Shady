//
//  Shaders15.metal
//  Shady
//
//  Metal shader functions for rendering a stylised but realistic lightning bolt.
//  The fragment shader synthesises a branching bolt by layering animated sine
//  displacements and fractal noise, while also adding a soft atmospheric glow.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float2 uv;
};

[[vertex]]
RasterizerData lightningVertexShader(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };

    RasterizerData out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = texCoords[vertexID];
    return out;
}

float hash21(float2 p) {
    p = fract(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash21(i + float2(0.0, 0.0));
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; ++i) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.1;
        amplitude *= 0.5;
    }
    return value;
}

float glowFalloff(float dist, float radius) {
    float q = dist / radius;
    return exp(-q * q);
}

[[fragment]]
float4 lightningFragmentShader(RasterizerData in [[stage_in]],
                               constant float2 &resolution [[buffer(0)]],
                               constant float &time [[buffer(1)]]) {
    float2 uv = in.uv;
    float aspect = resolution.x / max(resolution.y, 1.0);

    float2 centred = float2((uv.x - 0.5) * aspect, uv.y - 0.5);
    float y = uv.y;

    float displacement = 0.0;
    float frequency = 1.7;
    float amplitude = 0.32;

    for (int i = 0; i < 5; ++i) {
        float phase = time * (1.2 + float(i) * 0.35);
        float noiseContribution = fbm(float2(y * frequency * 1.3 + float(i) * 13.7, time * 0.6));
        displacement += sin(y * frequency * 6.28318 + phase + noiseContribution * 2.0) * amplitude;
        frequency *= 1.75;
        amplitude *= 0.55;
    }

    float mainBoltX = displacement;
    float distToCore = fabs(centred.x - mainBoltX);

    float flicker = 0.7 + 0.3 * sin(time * 45.0 + fbm(float2(time * 3.0, 4.0)) * 6.0);

    float core = glowFalloff(distToCore, 0.018) * flicker;
    float innerGlow = glowFalloff(distToCore, 0.05) * (0.6 + 0.4 * fbm(float2(time * 2.5, y * 5.0)));
    float outerGlow = glowFalloff(distToCore, 0.15) * 0.5;

    float branchMask1 = smoothstep(0.18, 0.28, y) * (1.0 - smoothstep(0.6, 0.68, y));
    float branchPath1 = mainBoltX + 0.25 + 0.05 * sin((y - 0.25) * 18.0 + time * 1.8);
    float branch1 = glowFalloff(fabs(centred.x - branchPath1), 0.022) * branchMask1;

    float branchMask2 = smoothstep(0.35, 0.45, y) * (1.0 - smoothstep(0.85, 0.93, y));
    float branchPath2 = mainBoltX - 0.22 + 0.04 * sin((y - 0.4) * 16.0 - time * 1.4);
    float branch2 = glowFalloff(fabs(centred.x - branchPath2), 0.02) * branchMask2;

    float sparks = pow(max(0.0, 1.0 - distToCore * 14.0), 3.0) * (0.3 + 0.7 * fbm(float2(centred.x * 30.0, y * 60.0 + time * 25.0)));

    float3 background = float3(0.015, 0.02, 0.05);
    float3 boltColour = float3(1.0, 0.98, 0.92);
    float3 glowColour = float3(0.36, 0.55, 0.95);

    float boltEnergy = core + branch1 + branch2;
    float aura = innerGlow + outerGlow;

    float3 colour = background;
    colour += aura * glowColour;
    colour += boltEnergy * boltColour;
    colour += sparks * float3(0.9, 0.95, 1.0);

    float stormDarken = 0.45 + 0.55 * fbm(float2(y * 1.3 - time * 0.4, time * 0.2));
    colour *= mix(0.55, 1.0, stormDarken);

    colour = clamp(colour, 0.0, 1.0);

    return float4(colour, 1.0);
}
