//
//  Shaders8.metal
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main8(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

// Function to create a star shape
float sdStar(float2 p, float r1, float r2, float sides, float angle) {
    float2 p2 = p;
    float a = atan2(p2.y, p2.x) + angle;
    float seg = a * (sides / 6.28318530718);
    a = ((floor(seg) + 0.5) / sides) * 6.28318530718;
    p2 = float2(cos(a), sin(a)) * length(p);
    float2 p3 = float2(abs(p2.x), p2.y);
    float2 p4 = p3 * r2;
    p4 = p4 - r1;
    return length(p4) * sign(p4.x);
}

fragment float4 fragment_main8(
    VertexOut in [[stage_in]],
    constant float &time [[buffer(0)]],
    constant float2 &resolution [[buffer(1)]]
) {
    float2 uv = in.uv;
    uv = uv * 2.0 - 1.0; // Convert to [-1,1] space
    uv.x *= resolution.x / resolution.y;
    
    float3 finalColor = float3(0.0);
    
    // Create multiple rotating stars with faster rotation
    for(float i = 0.0; i < 3.0; i++) {
        float t = time * (2.0 + i * 0.5); // Doubled base speed
        float2 center = float2(
            sin(t * 0.8) * 0.3, // Increased orbital speed
            cos(t * 1.0) * 0.3
        );
        
        // Rotate and scale the UV space for each star
        float2 starUV = uv - center;
        float angle = t * 1.0; // Doubled rotation speed
        float2 rotatedUV = float2(
            starUV.x * cos(angle) - starUV.y * sin(angle),
            starUV.x * sin(angle) + starUV.y * cos(angle)
        );
        
        // Create faster pulsating stars
        float scale = 0.3 + 0.1 * sin(t * 3.0); // Increased pulse speed
        float star = sdStar(rotatedUV, 0.1 * scale, 0.2 * scale, 5.0, t * 1.5); // Faster star spinning
        
        // Create faster color cycling
        float3 starColor = float3(
            0.5 + 0.5 * sin(t * 1.5 + i * 2.0),
            0.5 + 0.5 * sin(t * 2.0 + i * 1.5),
            0.5 + 0.5 * sin(t * 2.5 + i * 3.0)
        );
        
        // Add glow effect
        float glow = exp(-2.0 * abs(star));
        finalColor += starColor * glow;
    }
    
    // Add faster background effect
    float2 bgUV = uv * 3.0;
    float bgPattern = sin(bgUV.x * 5.0 + time * 3.0) * sin(bgUV.y * 5.0 + time * 3.0) * 0.1;
    finalColor += float3(0.1, 0.2, 0.3) * bgPattern;
    
    // Add faster color variation
    finalColor *= 1.0 + 0.2 * sin(uv.x * 10.0 + time * 3.0) * sin(uv.y * 10.0 + time * 3.0);
    
    return float4(finalColor, 1.0);
}
