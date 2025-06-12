//
// Shaders13.metal
// Shady
//
// Metal shaders for generating a drifting clouds effect.
// Includes a vertex shader for a full-screen quad and a fragment shader
// that uses Fractal Brownian Motion (fBm) to create cloud patterns.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Structure for vertex shader output, which becomes fragment shader input.
// Contains clip-space position and texture coordinates.
struct RasterizerData {
    float4 position [[position]]; // Output vertex position in clip space.
    float2 texCoord [[user(texturecoord)]]; // Output texture coordinates.
};

// Pass-through vertex shader for a full-screen quad.
// It generates the vertices and texture coordinates for a quad that covers the entire screen.
[[vertex]]
RasterizerData cloudVertexShader(uint vertexID [[vertex_id]]) { // vertex_id is the index of the current vertex.
    RasterizerData out;

    // Predefined full-screen quad vertices (positions in Normalized Device Coordinates - NDC)
    // and corresponding texture coordinates (UVs).
    // This forms two triangles (a triangle strip) that cover the screen.
    float2 positions[4] = {
        float2(-1.0, -1.0), // Bottom-left (NDC)
        float2( 1.0, -1.0), // Bottom-right (NDC)
        float2(-1.0,  1.0), // Top-left (NDC)
        float2( 1.0,  1.0)  // Top-right (NDC)
    };
    float2 texCoords[4] = {
        float2(0.0, 1.0), // UV for bottom-left
        float2(1.0, 1.0), // UV for bottom-right
        float2(0.0, 0.0), // UV for top-left
        float2(1.0, 0.0)  // UV for top-right
    };

    // Set the clip-space position for the current vertex.
    // z = 0.0 (on the near plane), w = 1.0 (no perspective division needed for orthographic projection).
    out.position = float4(positions[vertexID], 0.0, 1.0);
    // Pass through the texture coordinate for the current vertex.
    out.texCoord = texCoords[vertexID];
    return out;
}

// --- Noise functions (basic implementation for clouds) ---

// Generates a pseudo-random float value between 0.0 and 1.0 based on a 2D input vector.
// This is a common simple hash function used in procedural generation.
float random(float2 p) {
    // sin and dot products with large numbers create a chaotic, pseudo-random result.
    // fract() keeps the result in the [0,1) range.
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise function (Value Noise).
// Interpolates random values at integer grid points to create smoother noise.
float snoise(float2 uv) {
    float2 i = floor(uv); // Integer part of uv (grid cell coordinates)
    float2 f = fract(uv); // Fractional part of uv (position within the grid cell)

    // Apply smoothstep function (f*f*(3.0-2.0*f)) to f for smoother interpolation.
    // This is equivalent to Ken Perlin's improved noise fade curve (6t^5 - 15t^4 + 10t^3).
    f = f * f * (3.0 - 2.0 * f);

    // Get random values at the four corners of the grid cell.
    float a = random(i + float2(0.0, 0.0)); // Bottom-left corner
    float b = random(i + float2(1.0, 0.0)); // Bottom-right corner
    float c = random(i + float2(0.0, 1.0)); // Top-left corner
    float d = random(i + float2(1.0, 1.0)); // Top-right corner

    // Bilinear interpolation of the four corner values.
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion (fBm) for generating natural-looking patterns like clouds.
// It sums multiple layers (octaves) of noise at different frequencies and amplitudes.
float fbm(float2 uv, int octaves, float persistence) {
    float total = 0.0;        // Accumulator for the noise value.
    float frequency = 1.0;    // Initial frequency.
    float amplitude = 1.0;    // Initial amplitude.
    float maxValue = 0.0;     // Used to normalize the result to the [0,1] range.

    // Loop through the octaves.
    for (int i = 0; i < octaves; i++) {
        // Add noise at the current frequency and amplitude.
        total += snoise(uv * frequency) * amplitude;
        // Accumulate the maximum possible amplitude.
        maxValue += amplitude;
        // Reduce amplitude for the next octave (persistence < 1).
        amplitude *= persistence;
        // Increase frequency for the next octave (typically doubles).
        frequency *= 2.0;
    }
    // Normalize the total noise value.
    return total / maxValue;
}

// --- Fragment Shader for Clouds ---

// Generates the cloud effect.
// It calculates a sky gradient, then layers animated clouds generated using fbm noise,
// and finally blends them together.
[[fragment]]
float4 cloudFragmentShader(RasterizerData in [[stage_in]], // Input from vertex shader (interpolated texCoord)
                           constant float2 &resolution [[buffer(0)]], // Viewport resolution (width, height) passed from app
                           constant float &time [[buffer(1)]])        // Time elapsed, for animation, passed from app
{
    float2 uv = in.texCoord; // Normalized texture coordinates [0,1]
    // Flip Y coordinate if your texture coordinate system has (0,0) at the bottom-left.
    // Metal's default often has (0,0) at top-left for textures.
    // For full-screen shaders using texCoord from vertex shader, this depends on how texCoords were defined.
    // The provided vertex shader maps UVs with (0,0) at top-left, so `1.0 - uv.y` makes (0,0) bottom-left for shader logic.
    uv.y = 1.0 - uv.y;

    // Calculate sky color: a simple vertical gradient from light blue to a deeper blue.
    // mix interpolates between two values based on a third (uv.y here).
    float3 skyColor = mix(float3(0.6, 0.8, 1.0), /*light blue at bottom (uv.y=0)*/
                          float3(0.3, 0.6, 0.9), /*deeper blue at top (uv.y=1)*/
                          uv.y);

    // Cloud Generation:
    // Adjust UV coordinates for clouds to account for aspect ratio, preventing stretching.
    float2 cloudUV = uv * float2(resolution.x / resolution.y, 1.0);
    // Animate cloud UVs by adding time-dependent offsets to create a drifting effect.
    // Different speeds for x and y components give a more natural drift.
    cloudUV += float2(time * 0.05, time * 0.02);

    // Parameters for fbm clouds:
    // - cloudUV * 2.0: Input coordinate scaling. Larger values make clouds smaller/denser.
    // - 5: Number of octaves for fbm. More octaves = more detail (and more computation).
    // - 0.5: Persistence for fbm. Controls how much amplitude decreases for successive octaves.
    float cloudCover = 0.5; // Base threshold for cloud visibility. Range [0,1].
                            // Higher values mean fewer visible clouds as fbm output needs to be higher.
    float cloudDensity = fbm(cloudUV * 2.0, 5, 0.5);

    // Shape the clouds using smoothstep for softer edges.
    // This creates a transition zone around the `cloudCover` value.
    // Essentially, values slightly below `cloudCover` smoothly transition to 0 (transparent),
    // and values slightly above smoothly transition to 1 (opaque).
    cloudDensity = smoothstep(cloudCover - 0.1, cloudCover + 0.1, cloudDensity);

    // Define the color of the clouds (e.g., white).
    float3 cloudColor = float3(1.0, 1.0, 1.0);

    // Blend the sky color with the cloud color based on the calculated cloudDensity.
    // A cloudOpacity factor can be used to make clouds more or less translucent.
    float cloudOpacity = 0.8;
    float3 finalColor = mix(skyColor, cloudColor, cloudDensity * cloudOpacity);

    return float4(finalColor, 1.0); // Output final color with full alpha.
}
