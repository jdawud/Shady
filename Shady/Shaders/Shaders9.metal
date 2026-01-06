//
//  Shaders9.metal
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut09 {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut09 vertex_main9(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut09 out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

fragment float4 fragment_main9(
    VertexOut09 in [[stage_in]],
    constant float &time [[buffer(0)]],
    constant float2 &resolution [[buffer(1)]]
) {
    float2 uv = in.uv;
    uv.x *= resolution.x / resolution.y;
    
    // Create a checker pattern
    float2 grid = floor(uv * 10.0); // Adjust the 10.0 to change checker size
    float checker = fmod(grid.x + grid.y, 2.0);
    
    // Create strobing effect
    float strobe = sin(time * 10.0) * 0.5 + 0.5;
    
    // Create color cycling
    float3 color1 = float3(
        sin(time * 2.0) * 0.5 + 0.5,
        cos(time * 3.0) * 0.5 + 0.5,
        sin(time * 4.0) * 0.5 + 0.5
    );
    
    float3 color2 = float3(
        cos(time * 3.0) * 0.5 + 0.5,
        sin(time * 4.0) * 0.5 + 0.5,
        cos(time * 2.0) * 0.5 + 0.5
    );
    
    // Add some movement to the checkers
    float2 moveUV = uv + float2(
        sin(time + uv.y * 4.0) * 0.1,
        cos(time + uv.x * 4.0) * 0.1
    );
    
    grid = floor(moveUV * 10.0);
    float movingChecker = fmod(grid.x + grid.y, 2.0);
    
    // Blend between static and moving checkers
    float finalChecker = mix(checker, movingChecker, sin(time * 2.0) * 0.5 + 0.5);
    
    // Create the final color
    float3 finalColor = mix(color1, color2, finalChecker);
    
    // Add strobe effect
    finalColor *= strobe;
    
    // Add some edge glow
    float2 center = uv - 0.5;
    float vignette = 1.0 - length(center) * 0.8;
    vignette = smoothstep(0.0, 1.0, vignette);
    
    finalColor *= vignette;
    
    // Add some extra visual interest
    float flash = pow(sin(time * 15.0) * 0.5 + 0.5, 4.0) * 0.5;
    finalColor += flash;
    
    return float4(finalColor, 1.0);
}
