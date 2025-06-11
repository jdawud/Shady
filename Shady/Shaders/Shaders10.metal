//
//  Shaders10.metal
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut10 {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut10 vertex_main10(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut10 out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

// Hash function for single float
float hash10(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Hash function for randomization
float2 hash2_10(float2 p) {
    p = float2(dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Noise function for texture generation
float noise10(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    // Cubic Hermite interpolation
    float2 u = f * f * (3.0 - 2.0 * f);
    
    // Sample 4 corners
    float a = dot(hash2_10(i + float2(0.0, 0.0)), f - float2(0.0, 0.0));
    float b = dot(hash2_10(i + float2(1.0, 0.0)), f - float2(1.0, 0.0));
    float c = dot(hash2_10(i + float2(0.0, 1.0)), f - float2(0.0, 1.0));
    float d = dot(hash2_10(i + float2(1.0, 1.0)), f - float2(1.0, 1.0));
    
    // Interpolate
    return 0.5 + 0.5 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Creates a single raindrop with trail
float raindrop10(float2 uv, float2 center, float size, float blur) {
    float2 q = uv - center;
    
    // Main drop shape (more elongated teardrop)
    float2 dropShape = q * float2(2.5, 4.0);
    float drop = length(dropShape) - size;
    
    // Add trail effect
    float trail = max(0.0, q.y * 8.0); // Trail above the drop
    drop += trail * 0.1;
    
    // Smooth transition
    float result = smoothstep(blur, -blur, drop);
    
    // Add internal highlight
    float highlight = length(q + float2(size * 0.25, size * 0.25)) * 2.0;
    result += (1.0 - smoothstep(0.0, size * 2.0, highlight)) * 0.1;
    
    return result;
}

float2 distort10(float2 uv, float2 center, float size, float strength) {
    float2 delta = uv - center;
    float dist = length(delta);
    float falloff = smoothstep(size, 0.0, dist);
    return delta * falloff * strength;
}

float2 getDropDistortion10(float2 uv, float2 center, float size, float drop) {
    return distort10(uv, center, size * 2.0, 0.2) * drop;
}

fragment float4 fragment_main10(VertexOut10 vertexIn [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float2 &resolution [[buffer(1)]]) {
    float2 uv = vertexIn.uv;
    uv.x *= resolution.x / resolution.y;
    
    float2 totalDistortion = float2(0.0);
    float3 backgroundColor = float3(0.1, 0.12, 0.15); // Dark blue-gray background
    float3 color = backgroundColor;
    
    const int NUM_DROPS = 35; // More drops
    // Create multiple raindrops
    for(int i = 0; i < NUM_DROPS; i++) {
        float t = time + float(i) * 1.234;
        
        // More varied fall speeds
        float speed = 0.2 + hash10(float(i) * 0.789) * 0.3;
        // Add slight horizontal movement
        float xOffset = sin(t * hash10(float(i) * 0.333)) * 0.02;
        float2 center = float2(
            hash10(float(i) * 0.123) * 0.8 + 0.1 + xOffset,
            1.0 - fmod(t * speed + hash10(float(i) * 0.456), 1.2) // Longer fall distance
        );
        
        // More varied drop sizes
        float size = 0.008 + hash10(float(i) * 0.789) * 0.025;
        float blur = size * 0.5;
        
        float drop = raindrop10(uv, center, size, blur);
        float2 dropDistortion = getDropDistortion10(uv, center, size, drop);
        totalDistortion += dropDistortion * 0.25; // Slightly reduced distortion
        
        // More varied drop colors
        float3 dropColor = backgroundColor + float3(0.2, 0.22, 0.25) * (1.0 + hash10(float(i)));
        color = mix(color, dropColor, drop * 0.7);
    }
    
    // Apply accumulated distortion to background
    float2 finalUV = uv + totalDistortion;
    float3 distortedColor = mix(backgroundColor, color, 0.8);
    
    // Improved rain streaks
    float2 streakUV = finalUV;
    streakUV.y *= 1.5; // Stretch vertically
    
    // Multiple layers of streaks
    float streaks = 0.0;
    for(int i = 0; i < 3; i++) {
        float speed = 12.0 + float(i) * 4.0;
        float density = 25.0 + float(i) * 10.0;
        float strength = 0.03 / float(i + 1);
        
        float layer = fract(streakUV.y * density + time * speed + hash10(float(i)));
        layer = pow(layer, 8.0) * strength;
        
        // Randomize streak positions
        float xOffset = hash10(float(i) * 0.789) * 0.1;
        layer *= smoothstep(0.0, 0.1, fract(streakUV.x * 5.0 + xOffset));
        
        streaks += layer;
    }
    distortedColor += float3(streaks);
    
    // Improved glass effect
    float2 glassUV = uv * 15.0 + time * 0.05;
    float glass = noise10(glassUV) * 0.02;
    glass += noise10(glassUV * 2.0) * 0.01;
    distortedColor += float3(glass);
    
    return float4(distortedColor, 1.0);
}
