//
//  Shaders.metal
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut01 {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut01 vertex_main(uint vertexID [[vertex_id]]) {
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

    VertexOut01 out;
    out.position = positions[vertexID];
    out.uv = uvs[vertexID];
    return out;
}

fragment float4 fragment_main(VertexOut01 in [[stage_in]], constant float& time [[buffer(0)]]) {
    float r = sin(in.uv.x * 10.0 + time);
    float g = sin(in.uv.y * 10.0 + time);
    float b = sin(in.uv.x * 10.0 + in.uv.y * 10.0 + time);
    return float4(r, g, b, 1.0);
}



