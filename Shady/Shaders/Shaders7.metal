#include <metal_stdlib>
using namespace metal;

struct VertexOut07 {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms07 {
    packed_float2 resolution;
    float time;
    float padding; // Add padding to ensure 16-byte alignment
};

// Vertex shader for Shader 07 (northern lights noise effect)
vertex VertexOut07 vertex_shader_07(uint vertexID [[vertex_id]],
                               constant float2 *vertices [[buffer(0)]]) {
    VertexOut07 out;
    out.position = float4(vertices[vertexID], 0, 1);
    out.uv = (vertices[vertexID] + 1.0) * 0.5;
    return out;
}

float2 hash(float2 p) {
    p = float2(dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

static inline float noise(float2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    
    float2 i = floor(p + (p.x + p.y) * K1);
    float2 a = p - i + (i.x + i.y) * K2;
    float2 o = (a.x > a.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 b = a - o + K2;
    float2 c = a - 1.0 + 2.0 * K2;
    
    float3 h = max(0.5 - float3(dot(a,a), dot(b,b), dot(c,c)), 0.0);
    float3 n = h * h * h * h * float3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    
    return dot(n, float3(70.0, 70.0, 70.0));
}

// Fragment shader for Shader 07 (northern lights noise effect)
fragment float4 fragment_shader_07(VertexOut07 in [[stage_in]],
                                constant Uniforms07 &uniforms [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 resolution = uniforms.resolution;
    float time = uniforms.time * 5.0; // Much faster time scale
    
    float2 pos = uv * 2.0 - 1.0;
    pos.x *= resolution.x / resolution.y;
    
    // Create rapid rotating movement
    float2 rotatedPos = float2(
        pos.x * cos(time) - pos.y * sin(time),
        pos.x * sin(time) + pos.y * cos(time)
    );
    
    float3 color = float3(0.0);
    
    // Fast moving waves
    float waves = sin(rotatedPos.x * 10.0 + time * 3.0) * 
                 cos(rotatedPos.y * 8.0 - time * 4.0);
    
    // Rapid color cycling
    float3 color1 = float3(0.2 + 0.2 * sin(time * 2.0),
                          0.3 + 0.2 * cos(time * 3.0),
                          0.4 + 0.2 * sin(time * 4.0));
    
    // Moving noise patterns
    for (float i = 1.0; i < 4.0; i++) {
        float2 noisePos = rotatedPos;
        noisePos.x += time * i * 0.5;
        noisePos.y -= time * (5.0 - i) * 0.3;
        
        float noiseVal = noise(noisePos * (2.0 + i) + float2(waves));
        color += color1 * noiseVal * (0.3 / i);
    }
    
    // Add rapid swirling effect
    float2 swirl = pos;
    float swirlAngle = length(swirl) * 5.0 - time * 3.0;
    swirl = float2(
        swirl.x * cos(swirlAngle) - swirl.y * sin(swirlAngle),
        swirl.x * sin(swirlAngle) + swirl.y * cos(swirlAngle)
    );
    
    // Additional fast-moving noise layer
    float swirlNoise = noise(swirl * 3.0 + time);
    color += float3(0.2, 0.3, 0.4) * swirlNoise * 0.3;
    
    // Rapid color pulsing
    float pulse = 0.8 + 0.2 * sin(time * 3.0);
    color *= pulse;
    
    // Add some high-contrast edges
    float edges = smoothstep(0.2, 0.8, noise(rotatedPos * 4.0 + time));
    color = mix(color, color * 1.5, edges);
    
    return float4(color, 1.0);
}
