//
//  Shaders16.metal
//  Shady
//
//  Warp drive / hyperspace star streak effect shader.
//  Stars fly outward from a central point creating the classic
//  "jump to warp speed" tunnel effect.
//

#include <metal_stdlib>
using namespace metal;

// Vertex output for full-screen quad
struct WarpVertexOut {
    float4 position [[position]];
    float2 uv;
};

/// Vertex shader - generates full-screen quad
[[vertex]]
WarpVertexOut warpVertexShader(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    
    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    
    WarpVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = texCoords[vertexID];
    return out;
}

/// Hash function for pseudo-random values
static inline float warpHash(float n) {
    return fract(sin(n) * 43758.5453123);
}

/// Fragment shader - renders the warp drive starfield effect
/// Stars originate near center and streak outward past the viewer
[[fragment]]
float4 warpFragmentShader(WarpVertexOut in [[stage_in]],
                          constant float2 &resolution [[buffer(0)]],
                          constant float &time [[buffer(1)]]) {
    
    // Center and aspect-correct UV coordinates
    float2 uv = in.uv - 0.5;
    float aspect = resolution.x / max(resolution.y, 1.0);
    uv.x *= aspect;
    
    // Calculate distance from center for radial effects
    float dist = length(uv);
    
    // Deep space background - dark blue-black
    float3 color = float3(0.0, 0.01, 0.03);
    
    // Warp tunnel parameters
    float speed = 1.8;           // Overall warp speed
    float numStars = 150.0;      // Total number of star streaks
    float tunnelDepth = 3.0;     // How far back the tunnel extends
    
    // Create star streaks
    for (float i = 0.0; i < numStars; i++) {
        // Unique random values for each star
        float seed = i + 0.5;
        float starAngle = warpHash(seed * 1.234) * 6.28318;      // Random angle around center
        float starSpeed = 0.5 + warpHash(seed * 2.345) * 1.0;    // Vary individual star speeds
        float starBrightness = 0.3 + warpHash(seed * 3.456) * 0.7;
        float starDepth = warpHash(seed * 4.567);                 // Random starting depth
        
        // Calculate star's current position along its journey
        // Stars move from depth (near center) toward viewer (outer edge)
        float z = fmod(starDepth + time * speed * starSpeed, tunnelDepth);
        
        // Convert depth to screen radius (perspective projection)
        // As z decreases (star gets closer), radius increases
        float radius = 0.02 / (z + 0.1);
        
        // Star position in screen space
        float2 starPos = float2(cos(starAngle), sin(starAngle)) * radius;
        
        // Calculate streak length based on speed and proximity
        // Closer stars (smaller z) have longer streaks
        float streakLength = (0.15 / (z + 0.2)) * starSpeed;
        
        // Direction of streak (radially outward from center)
        float2 streakDir = normalize(starPos);
        
        // Distance from current pixel to the star streak line
        float2 toPixel = uv - starPos;
        
        // Project pixel onto streak line
        float alongStreak = dot(toPixel, streakDir);
        
        // Clamp to streak bounds (streak extends behind star position)
        float clampedAlong = clamp(alongStreak, -streakLength, 0.0);
        
        // Perpendicular distance to streak line
        float perpDist = length(toPixel - streakDir * clampedAlong);
        
        // Streak width - thinner at the tail, wider at the head
        float headWidth = 0.003 + 0.01 / (z + 0.3);
        float tailWidth = headWidth * 0.3;
        float streakWidth = mix(tailWidth, headWidth, (clampedAlong + streakLength) / streakLength);
        
        // Calculate brightness with smooth falloff
        float brightness = smoothstep(streakWidth, 0.0, perpDist);
        
        // Fade along the streak (brighter at head, dimmer at tail)
        float streakFade = smoothstep(-streakLength, 0.0, alongStreak);
        brightness *= streakFade;
        
        // Closer stars are brighter
        brightness *= 1.0 / (z + 0.3);
        brightness *= starBrightness;
        
        // Star color - mostly white/blue with slight variation
        float3 starColor = float3(0.9, 0.95, 1.0);
        float colorVar = warpHash(seed * 5.678);
        if (colorVar > 0.85) {
            starColor = float3(1.0, 0.85, 0.7);  // Warm yellow-white
        } else if (colorVar > 0.7) {
            starColor = float3(0.7, 0.85, 1.0);  // Cool blue
        }
        
        // Add slight blue shift for speed effect on fast-moving stars
        float blueShift = starSpeed * 0.1;
        starColor.b += blueShift;
        starColor = clamp(starColor, 0.0, 1.0);
        
        // Accumulate star contribution
        color += starColor * brightness * 0.8;
    }
    
    // Add central glow - the "origin point" of the warp
    float coreGlow = exp(-dist * 15.0) * 0.3;
    float corePulse = 0.8 + 0.2 * sin(time * 4.0);
    color += float3(0.6, 0.7, 1.0) * coreGlow * corePulse;
    
    // Subtle inner glow ring
    float ringGlow = exp(-abs(dist - 0.05) * 50.0) * 0.15;
    color += float3(0.5, 0.6, 0.9) * ringGlow;
    
    // Slight blue tint toward edges for "warp field" effect
    float edgeTint = smoothstep(0.3, 0.8, dist);
    color += float3(0.05, 0.08, 0.15) * edgeTint;
    
    // Subtle vignette
    float vignette = 1.0 - dist * 0.4;
    color *= max(vignette, 0.6);
    
    // Clamp and apply slight HDR bloom feel
    color = clamp(color, 0.0, 1.0);
    color = pow(color, float3(0.9)); // Slight gamma lift
    
    return float4(color, 1.0);
}
