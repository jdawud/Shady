#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float time;
    float2 touch;
    float2 padding; // Ensure 16-byte alignment
};

vertex VertexOut vertex_shader_12(uint vertexID [[vertex_id]],
                               constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID], 0, 1);
    out.uv = (vertices[vertexID] + 1.0) * 0.5;
    return out;
}

inline float2 hash2(float2 p) {
    return fract(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
}

inline float noise12(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(dot(hash2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                   dot(hash2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
               mix(dot(hash2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                   dot(hash2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
}

fragment float4 fragment_shader_12(VertexOut in [[stage_in]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 resolution = uniforms.resolution;
    float time = uniforms.time;
    float2 touch = uniforms.touch / resolution;
    
    // Create wave effect
    float2 p = uv * 8.0;
    float2 i = p;
    float c = 0.0;
    float inten = 0.005;
    float t = time * 0.2; // Initialize t outside the loop
    
    for (int n = 0; n < 5; n++) {
        float adjustedTime = t * (1.0 - (3.5 / float(n + 1))); // Use a new variable for clarity
        i = p + float2(cos(adjustedTime - i.x) + sin(adjustedTime + i.y),
                       sin(adjustedTime - i.y) + cos(adjustedTime + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + adjustedTime) / inten),
                                 p.y / (cos(i.y + adjustedTime) / inten)));
    }
    
    c = c / 5.0;
    c = 1.5 - sqrt(c);
    
    // Add touch interaction
    float touchEffect = smoothstep(0.0, 0.2, 1.0 - distance(uv, touch));
    c -= touchEffect * 0.5;
    
    // Create silvery color
    float3 color = mix(float3(0.7, 0.7, 0.8), float3(0.9, 0.9, 1.0), c);
    color += float3(0.1, 0.1, 0.1) * noise12(uv * 100.0 + time);
    
    return float4(color, 1.0);
}
