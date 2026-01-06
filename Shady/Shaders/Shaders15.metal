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

// Forward declaration so valueNoise1D can use it
static inline float hash21(float2 p);

// 1D value noise built from the same hash, for jagged bolt path without looking sinusoidal
static inline float valueNoise1D(float t) {
    float i = floor(t);
    float f = fract(t);
    float a = hash21(float2(i, 0.0));
    float b = hash21(float2(i + 1.0, 0.0));
    float u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u);
}

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

static inline float hash21(float2 p) {
    p = fract(p * float2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

static inline float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash21(i + float2(0.0, 0.0));
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static inline float fbm(float2 p) {
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

static inline float glowFalloff(float dist, float radius) {
    float q = dist / radius;
    return exp(-q * q);
}

// Signed distance from point p to segment a-b (returns non-negative here)
static inline float sdSegment(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

// Displacement function for the bolt x-position as a function of y in [0,1]
static inline float dispX(float y01, float t) {
    float dx = 0.0;
    float f = 2.0;
    float a = 0.25;
    // value-noise octaves to create kinked, non-sinusoidal shape
    for (int i = 0; i < 4; ++i) {
        float n = valueNoise1D(y01 * f + t * 0.2 + float(i) * 3.17) * 2.0 - 1.0;
        dx += n * a;
        f *= 1.9;
        a *= 0.55;
    }
    // small, fast jitter to animate
    dx += (valueNoise1D(y01 * 40.0 + t * 6.0) - 0.5) * 0.008;
    return dx;
}

[[fragment]]
float4 lightningFragmentShader(RasterizerData in [[stage_in]],
                               constant float2 &resolution [[buffer(0)]],
                               constant float &time [[buffer(1)]]) {
    float2 uv = in.uv;
    float aspect = resolution.x / max(resolution.y, 1.0);

    float2 p = float2((uv.x - 0.5) * aspect, uv.y - 0.5);

    // Build main bolt as a polyline along y in [-0.5, 0.5]
    const int N = 42;
    float minDistMain = 1e9;
    for (int i = 0; i < N; ++i) {
        float y0c = -0.5 + (float(i)     / float(N)) * 1.0;
        float y1c = -0.5 + (float(i + 1) / float(N)) * 1.0;
        // Map to 0..1 for displacement function
        float y0 = y0c + 0.5;
        float y1 = y1c + 0.5;
        float2 a = float2(dispX(y0, time), y0c);
        float2 b = float2(dispX(y1, time), y1c);
        minDistMain = min(minDistMain, sdSegment(p, a, b));
    }

    // Side branches: short polylines that peel off then decay
    float minDistBranch = 1e9;
    // Two branches starting around lower/mid regions
    for (int bIdx = 0; bIdx < 2; ++bIdx) {
        float yStart = (bIdx == 0) ? -0.15 : 0.15;
        float dir    = (bIdx == 0) ? 1.0 : -1.0; // left/right
        const int BN = 9;
        float2 last = float2(dispX(yStart + 0.5, time), yStart);
        for (int j = 1; j < BN; ++j) {
            float yj = yStart + float(j) * 0.02;
            float bend = (valueNoise1D(yj * 25.0 + time * 0.8 + float(bIdx) * 11.0) - 0.5) * 0.08;
            float2 cur = float2(dispX(yj + 0.5, time) + dir * (0.10 + 0.02 * float(j)) + bend,
                                yj);
            minDistBranch = min(minDistBranch, sdSegment(p, last, cur));
            last = cur;
        }
    }

    // Subtle flicker and rare flashes
    float flicker = 0.8 + 0.2 * valueNoise1D(time * 6.0);
    float bigFlash = step(0.995, valueNoise1D(time * 0.7));
    float flashBoost = mix(1.0, 1.3, bigFlash);

    // Crisp core with tight radius, soft inner/outer corona using distances
    float core      = glowFalloff(minDistMain,   0.006) * flicker * flashBoost;
    float innerGlow = glowFalloff(minDistMain,   0.030) * 0.9;
    float outerGlow = glowFalloff(minDistMain,   0.110) * 0.55;
    float branchGlow= glowFalloff(min(minDistBranch, 1e6), 0.020);

    // Micro halos near core (faint texture only)
    float micro = pow(max(0.0, 1.0 - minDistMain * 24.0), 3.0) * (0.18 + 0.82 * valueNoise1D(p.x * 22.0 + (p.y+0.5) * 65.0 + time * 14.0));

    float sparks = pow(max(0.0, 1.0 - minDistMain * 16.0), 3.0) * (0.25 + 0.75 * fbm(float2(p.x * 30.0, (p.y+0.5) * 60.0 + time * 25.0)));

    // Color palette: hotter white core, cool blue glow
    float3 background = float3(0.008, 0.014, 0.035);
    float3 boltColour = float3(1.00, 0.995, 0.975);
    float3 glowColour = float3(0.42, 0.68, 1.00);

    float boltEnergy = core + branchGlow * 0.8 + micro * 0.35;
    float aura = innerGlow + outerGlow + branchGlow * 0.5;

    float3 colour = background;
    colour += aura * glowColour;
    colour += boltEnergy * boltColour;
    colour += sparks * float3(0.9, 0.95, 1.0);

    // Subtle cloud darkening
    float stormDarken = 0.45 + 0.55 * fbm(float2(p.y * 1.3 - time * 0.4, time * 0.2));
    colour *= mix(0.55, 1.0, stormDarken);

    // Exposure bloom on flashes
    colour *= mix(1.0, 1.25, bigFlash * 0.8);

    colour = clamp(colour, 0.0, 1.0);

    return float4(colour, 1.0);
}
