//
//  Shaders2.metal
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut02 {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut02 vertex_main2(uint vertexID [[vertex_id]]) { // Renamed to vertex_main2
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

    VertexOut02 out;
    out.position = positions[vertexID];
    out.uv = uvs[vertexID];
    return out;
}

fragment float4 fragment_main2(VertexOut02 in [[stage_in]], constant float& time [[buffer(0)]]) {
    float2 uv = in.uv * 2.0 - 1.0;
    float swirl = sin(uv.x * 10.0 + uv.y * 10.0 + time);
    return float4(swirl, 0.5 + swirl * 0.5, uv.x * uv.y, 1.0);
}



