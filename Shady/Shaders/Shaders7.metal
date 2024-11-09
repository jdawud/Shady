#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    packed_float2 resolution;
    float time;
    float padding; // Add padding to ensure 16-byte alignment
};

vertex VertexOut vertex_shader(uint vertexID [[vertex_id]],
                               constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID], 0, 1);
    out.uv = (vertices[vertexID] + 1.0) * 0.5;
    return out;
}

float2 hash(float2 p) {
    p = float2(dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(float2 p) {
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

fragment float4 fragment_shader(VertexOut in [[stage_in]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 resolution = uniforms.resolution;
    float time = uniforms.time;
    
    float2 pos = uv * 2.0 - 1.0;
    pos.x *= resolution.x / resolution.y;
    
    float3 color = float3(0.0);
    
    // Base layer
    for (float i = 1.0; i < 6.0; i++) {
        float2 q = pos * (1.0 - i * 0.05);
        q.y -= time * 0.1 - i * 0.2;
        float strength = 1.0 / i;
        color += float3(0.0, 0.3, 0.5) * strength * smoothstep(0.0, 0.1, noise(q * 3.0));
    }
    
    // Highlight layer
    for (float i = 1.0; i < 4.0; i++) {
        float2 q = pos * (1.0 - i * 0.1);
        q.y -= time * 0.2 + i * 0.3;
        float strength = 1.0 / i;
        color += float3(0.2, 0.5, 0.3) * strength * smoothstep(0.0, 0.1, noise(q * 5.0));
    }
    
    // Adjust color and intensity
    color = pow(color, float3(1.5));
    color = smoothstep(0.0, 1.0, color);
    
    return float4(color, 1.0);
}
