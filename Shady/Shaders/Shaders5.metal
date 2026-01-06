//
//  Shaders5.metal
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

#include <metal_stdlib>
using namespace metal;

// Structure to pass data from the vertex shader to the fragment shader
struct VertexOut05 {
    float4 position [[position]];
    float2 uv; // UV coordinates to pass to the fragment shader
};

// Vertex shader
vertex VertexOut05 vertex_main5(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),  // Bottom left
        float2( 1.0, -1.0),  // Bottom right
        float2(-1.0,  1.0),  // Top left
        float2( 1.0,  1.0)   // Top right
    };

    VertexOut05 out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5; // Convert from [-1,1] to [0,1] UV space
    return out;
}

// Function to create smooth circles (blobs)
float sdCircle(float2 p, float2 center, float radius) {
    return length(p - center) - radius;
}

// Fragment shader
fragment float4 fragment_main5(
    VertexOut05 in [[stage_in]],
    constant float &time [[buffer(0)]],
    constant float2 &resolution [[buffer(1)]]
) {
    // Normalized coordinates
    float2 uv = in.uv;
    uv.x *= resolution.x / resolution.y; // Correct aspect ratio

    // Define some moving "blobs" with different parameters
    float2 center1 = float2(sin(time * 0.6) * 0.3 + 0.5, cos(time * 0.8) * 0.3 + 0.5);
    float2 center2 = float2(cos(time * 0.9) * 0.3 + 0.5, sin(time * 0.7) * 0.3 + 0.5);
    float2 center3 = float2(sin(time * 1.1) * 0.4 + 0.5, cos(time * 1.2) * 0.4 + 0.5);

    // Signed distance field for circles
    float dist1 = sdCircle(uv, center1, 0.2);
    float dist2 = sdCircle(uv, center2, 0.15);
    float dist3 = sdCircle(uv, center3, 0.18);

    // Smooth minimum to blend the blobs together
    float smoothBlob = min(dist1, min(dist2, dist3));

    // Color based on distance (smooth fade)
    float blobColor = smoothstep(0.2, 0.0, smoothBlob); // Smooth edge

    // Set the color with a gradient effect
    float3 color = float3(0.9 + 0.1 * cos(time + uv.x * 10.0),
                          0.5 + 0.5 * cos(time * 0.9 + uv.y * 10.0),
                          0.7 + 0.3 * cos(time * 1.2 + uv.y * 15.0)) * blobColor;

    return float4(color, 1.0);
}



