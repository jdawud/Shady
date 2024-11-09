//
//  Shaders4.metal
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//
 
#include <metal_stdlib>
using namespace metal;

// Structure to pass data from the vertex shader to the fragment shader
struct VertexOut {
    float4 position [[position]];
    float4 fragCoord; // This will pass the position to the fragment shader
};

// Vertex shader
vertex VertexOut vertex_main4(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),  // Bottom left
        float2( 1.0, -1.0),  // Bottom right
        float2(-1.0,  1.0),  // Top left
        float2( 1.0,  1.0)   // Top right
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.fragCoord = out.position;  // Pass the position to the fragment shader
    return out;
}

// Fragment shader
fragment float4 fragment_main4(
    VertexOut in [[stage_in]],  // Use the structure to receive the input
    constant float &time [[buffer(0)]],
    constant float2 &resolution [[buffer(1)]]
) {
    // Normalized coordinates
    float2 uv = in.fragCoord.xy / resolution;
    uv = uv * 2.0 - 1.0; // Center the coordinates around (0, 0)
    uv.x *= resolution.x / resolution.y;

    // Creating a bouncing wave effect with sine
    float wave = sin(uv.y * 10.0 + time * 3.0) * 0.1;
    float bounce = sin(time * 2.0 + length(uv) * 5.0) * 0.1;

    // Calculate color based on wave displacement
    float3 color = float3(0.5 + 0.5 * cos(time + uv.x * 3.0 + wave + bounce),
                          0.5 + 0.5 * cos(time + uv.y * 3.0 + wave),
                          0.7 + 0.3 * cos(time + wave * 2.0));

    return float4(color, 1.0);
}






