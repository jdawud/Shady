//
//  Shaders3.metal
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut03 {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut03 vertex_main3(uint vertexID [[vertex_id]]) {
    float4 positions[4] = {
        float4(-1.0, -1.0, 0.0, 1.0),
        float4( 1.0, -1.0, 0.0, 1.0),
        float4(-1.0,  1.0, 0.0, 1.0),
        float4( 1.0,  1.0, 0.0, 1.0)
    };
    float2 uvs[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };

    VertexOut03 out;
    out.position = positions[vertexID];
    out.uv = uvs[vertexID];
    return out;
}

fragment float4 fragment_main3(VertexOut03 in [[stage_in]], constant float& time [[buffer(0)]]) {
    float2 uv = in.uv * 2.0 - 1.0;  // Normalized coordinates from -1 to 1
    float distort = sin(uv.x * 10.0 + time) * sin(uv.y * 10.0 + time); // Distortion factor

    // Liquid-like color with metallic sheen
    float metallicEffect = (sin(uv.x * 5.0 + time * 2.0) + cos(uv.y * 5.0 + time * 2.0)) * 0.5;
    float r = abs(distort * 0.6 + metallicEffect);
    float g = abs(distort * 0.4 + metallicEffect);
    float b = abs(distort * 0.9 + metallicEffect);

    return float4(r, g, b, 1.0);  // Metallic liquid look with dynamic distortion
}



