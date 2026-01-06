//
//  Shaders6.metal
//  Shady
//
//  Created by Junaid Dawud on 11/5/24.
//

#include <metal_stdlib>
using namespace metal;

// Struct to pass data from Swift to the shader
struct ShaderData06 {
    float2 resolution;
    float time;
};

// Vertex shader for Shader 06 (glowing metaball star effect)
vertex float4 vertexShader06(uint vertexID [[vertex_id]],
                           constant float2 *vertices [[buffer(0)]]) {
    return float4(vertices[vertexID], 0, 1);
}

// Helper function to create metaballs
float metaball(float2 p, float2 center, float radius) {
    return radius / length(p - center);
}

// Fragment shader for Shader 06 (glowing metaball star effect)
fragment float4 fragmentShader06(float4 position [[position]],
                               constant ShaderData06 &shaderData [[buffer(0)]]) {
    float2 uv = position.xy / shaderData.resolution;
    float aspect = shaderData.resolution.x / shaderData.resolution.y;
    uv.x *= aspect;
    
    // Create several metaballs with more dynamic movement
    float m1 = metaball(uv, float2(0.4 + 0.2 * sin(shaderData.time * 0.5), 0.5 + 0.2 * cos(shaderData.time * 0.7)), 0.15 + 0.05 * sin(shaderData.time));
    float m2 = metaball(uv, float2(0.6 + 0.2 * sin(shaderData.time * 0.8), 0.5 + 0.2 * cos(shaderData.time * 0.9)), 0.12 + 0.04 * cos(shaderData.time * 1.1));
    float m3 = metaball(uv, float2(0.5 + 0.3 * sin(shaderData.time * 0.6), 0.3 + 0.3 * cos(shaderData.time * 0.7)), 0.1 + 0.03 * sin(shaderData.time * 1.2));
    float m4 = metaball(uv, float2(0.5 + 0.25 * sin(shaderData.time * 0.9), 0.7 + 0.25 * cos(shaderData.time * 0.8)), 0.14 + 0.04 * cos(shaderData.time * 0.9));
    
    // Combine metaballs
    float metaballs = m1 + m2 + m3 + m4;
    
    // Create color based on metaball value
    float3 color = float3(0.8, 0.2, 0.1); // Base red color
    color *= smoothstep(1.0, 1.1, metaballs); // Smooth edge
    color += float3(0.2, 0.1, 0) * (sin(shaderData.time * 0.7) * 0.5 + 0.5); // More pronounced color variation over time
    
    // Add glow effect
    color += float3(0.8, 0.4, 0.2) * pow(metaballs, 4.0) * 0.4; // Stronger glow effect
    
    return float4(color, 1.0);
}


