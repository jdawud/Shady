//
//  Shaders11.metal
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut11 {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut11 vertex_main11(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut11 out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

// Hash function for randomization
inline float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

inline float2 hash21(float p) {
    float3 p3 = fract(float3(p) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// Creates a single firework explosion
float3 firework(float2 uv, float2 center, float time, float seed) {
    // Reduced number of particles for better performance
    const int NUM_PARTICLES = 50;
    float3 color = float3(0.0);
    
    // Base color with minimum brightness
    float3 baseColor = float3(
        0.5 + hash11(seed * 1.234) * 0.5,
        0.5 + hash11(seed * 2.345) * 0.5,
        0.5 + hash11(seed * 3.456) * 0.5
    );
    
    // Create particles
    for(int i = 0; i < NUM_PARTICLES; i++) {
        float particleSeed = seed + float(i);
        float2 dir = hash21(particleSeed) * 2.0 - 1.0;
        float speed = 0.8 + hash11(particleSeed) * 0.7;
        float size = 0.003 + hash11(particleSeed * 1.234) * 0.004;
        
        // Simple position calculation
        float2 pos = center + dir * time * speed;
        pos.y -= time * time * 0.15;
        
        float2 particleDelta = uv - pos;
        float particleDist = length(particleDelta);
        
        // Simplified particle rendering
        float brightness = smoothstep(size, 0.0, particleDist) * 
                         smoothstep(1.0, 0.0, time);
        
        // Simplified trail
        float trail = smoothstep(size * 2.0, 0.0, particleDist) * 
                     smoothstep(1.0, 0.0, time * 1.5) * 0.5;
        
        float glow = brightness + trail;
        color += baseColor * glow * 1.5;
    }
    
    return color;
}

fragment float4 fragment_main11(VertexOut11 vertexIn [[stage_in]],
                              constant float &time [[buffer(0)]],
                              constant float2 &resolution [[buffer(1)]]) {
    float2 uv = vertexIn.uv;
    uv.x *= resolution.x / resolution.y;
    
    float3 color = float3(0.0);
    
    // Reduced number of concurrent fireworks
    const int NUM_FIREWORKS = 5;
    
    for(int i = 0; i < NUM_FIREWORKS; i++) {
        float seed = float(i) * 123.456;
        
        // Simplified timing
        float cycleLength = 4.0;
        float offset = hash11(seed) * cycleLength;
        float localTime = fmod(time + offset, cycleLength);
        
        // Simple fade between cycles
        float fade = smoothstep(cycleLength - 0.5, cycleLength, localTime);
        float visibility = 1.0 - fade;
        
        if (visibility > 0.0) {
            float2 center = float2(
                0.1 + hash11(seed + floor((time + offset) / cycleLength)) * 0.8,
                0.2 + hash11((seed + 1.234) + floor((time + offset) / cycleLength)) * 0.6
            );
            
            color += firework(uv, center, localTime, seed) * visibility;
        }
    }
    
    // Simplified bloom with fewer samples
    float3 bloom = float3(0.0);
    const int BLUR_SAMPLES = 4;
    float bloomSize = 0.005;
    
    for(int i = 0; i < BLUR_SAMPLES; i++) {
        float angle = float(i) * 3.14159 * 2.0 / float(BLUR_SAMPLES);
        float2 offset = float2(cos(angle), sin(angle)) * bloomSize;
        bloom += firework(uv + offset, float2(0.5), time, 1.0);
    }
    color += bloom * 0.2;
    
    // Background
    float3 bg = mix(float3(0.0, 0.0, 0.02), float3(0.0), uv.y);
    color += bg;
    
    return float4(color, 1.0);
}
