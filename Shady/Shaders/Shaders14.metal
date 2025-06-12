//
// Shaders14.metal
// Shady
//
// Metal shaders for simulating a lava lamp effect using metaballs.
// The fragment shader calculates the influence of several moving "blobs"
// to determine pixel color, creating an organic, fluid visual.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// RasterizerData: Defines the structure of data passed from the vertex shader
// to the fragment shader. It includes the vertex position in clip space
// and texture coordinates for mapping.
struct RasterizerData {
    float4 position [[position]]; // Homogeneous clip-space position.
    float2 texCoord [[user(texturecoord)]]; // Texture coordinates (UV).
};

// Vertex Shader: lavaLampVertexShader
// A simple pass-through shader that generates a full-screen quad.
// The quad's vertices are defined in Normalized Device Coordinates (NDC)
// and texture coordinates are set up to map the entire "texture" (screen) space.
[[vertex]]
RasterizerData lavaLampVertexShader(uint vertexID [[vertex_id]]) { // vertexID is the index of the current vertex.
    RasterizerData out;
    // Predefined positions for a triangle strip covering -1 to 1 in X and Y.
    float2 positions[4] = {
        float2(-1.0, -1.0), // Bottom-left
        float2( 1.0, -1.0), // Bottom-right
        float2(-1.0,  1.0), // Top-left
        float2( 1.0,  1.0)  // Top-right
    };
    // Standard texture coordinates, mapping (0,0) to top-left and (1,1) to bottom-right.
    float2 texCoords[4] = {
        float2(0.0, 1.0), // Corresponds to bottom-left if Y is flipped later, or top-left if not.
        float2(1.0, 1.0), // Corresponds to bottom-right or top-right.
        float2(0.0, 0.0), // Corresponds to top-left or bottom-left.
        float2(1.0, 0.0)  // Corresponds to top-right or bottom-right.
    };
    // Output position directly; z=0, w=1 for basic 2D rendering.
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = texCoords[vertexID];
    return out;
}

// MetaBlob: Structure defining the properties of a single metaball.
struct MetaBlob {
    float2 position; // Center position of the blob in a conceptual normalized space.
    float2 velocity; // Movement vector (speed and direction).
    float radius;    // Radius of the blob, affecting its influence.
    float3 color;    // Base color of the blob.
};

// Fragment Shader: lavaLampFragmentShader
// Calculates the color of each pixel to create the lava lamp effect.
// It simulates multiple metaballs moving and merging.
[[fragment]]
float4 lavaLampFragmentShader(RasterizerData in [[stage_in]], // Data from vertex shader (interpolated texCoord).
                              constant float2 &resolution [[buffer(0)]], // Viewport resolution (width, height).
                              constant float &time [[buffer(1)]])        // Elapsed time for animation.
{
    float2 uv = in.texCoord; // UV coordinates from vertex shader, typically [0,1].

    // Correct aspect ratio for UV coordinates. This ensures that calculations
    // based on distance (like metaballs) appear circular rather than stretched.
    // It maps the UV space to a coordinate system where one unit in X is the same
    // visual length as one unit in Y.
    float2 aspectCorrectedUV = uv * float2(resolution.x / resolution.y, 1.0);

    // Define properties for 4 metaballs.
    // For a more dynamic effect, these could be passed in via a buffer/uniform.
    // Here, they are hardcoded for simplicity.
    MetaBlob blobs[4];

    // Blob 1 (Red) - Initial properties
    blobs[0].position = float2(0.2, 0.2); // Initial conceptual normalized position
    blobs[0].velocity = float2(0.03, 0.015); // Movement speed and direction
    blobs[0].radius = 0.15;
    blobs[0].color = float3(1.0, 0.2, 0.1); // Reddish color

    // Blob 2 (Green) - Initial properties
    blobs[1].position = float2(0.8, 0.3);
    blobs[1].velocity = float2(-0.02, 0.025);
    blobs[1].radius = 0.12;
    blobs[1].color = float3(0.2, 1.0, 0.3); // Greenish color

    // Blob 3 (Blue) - Initial properties
    blobs[2].position = float2(0.4, 0.7);
    blobs[2].velocity = float2(0.01, -0.035);
    blobs[2].radius = 0.18;
    blobs[2].color = float3(0.1, 0.3, 1.0); // Bluish color

    // Blob 4 (Yellow) - Initial properties
    // Initial position considers aspect correction for a more consistent starting point
    // if the view is not square. Here, assumes position is within the aspect-corrected space.
    blobs[3].position = float2(0.6, 0.6); // This will be scaled by aspect ratio below.
    blobs[3].velocity = float2(-0.015, -0.02);
    blobs[3].radius = 0.10;
    blobs[3].color = float3(1.0, 0.9, 0.2); // Yellowish color

    // Define screen boundaries for blob movement in aspect-corrected space.
    // X coordinates will range from 0 to (resolution.x / resolution.y).
    // Y coordinates will range from 0 to 1.0.
    float xMax = resolution.x / resolution.y;
    float yMax = 1.0; // UV space is typically normalized [0,1]

    // Animate blob positions.
    // This shader implements stateless animation: positions are calculated from initial
    // values, velocity, and absolute time. This means the shader doesn't remember
    // previous positions, but recalculates each frame.
    // For complex simulations, CPU-side updates passed as uniforms are often preferred.
    for (int i = 0; i < 4; ++i) {
        // Define initial positions in aspect-corrected space to ensure they scale correctly.
        float2 initialPos;
        if (i==0) initialPos = float2(0.2, 0.2) * float2(xMax, yMax);
        else if (i==1) initialPos = float2(0.8, 0.3) * float2(xMax, yMax);
        else if (i==2) initialPos = float2(0.4, 0.7) * float2(xMax, yMax);
        else initialPos = float2(0.6, 0.6) * float2(xMax, yMax); // Blob 3 initial was aspect corrected, adjust here.
                                                                   // The original blobs[3].position for yellow blob was already considering aspect ratio.
                                                                   // For consistency in this loop, we use a base normalized position and scale it.
                                                                   // Let's adjust blob 3's initial conceptual pos to be float2(0.6 / (resolution.x / resolution.y) , 0.6) if it was pre-corrected.
                                                                   // Or, simpler: define all initialPos in [0,1]x[0,1] and then scale.
                                                                   // The provided code for blobs[3] was float2(0.6 * resolution.x / resolution.y, 0.6);
                                                                   // This is already aspect corrected. So for this loop, we should use its original definition.
                                                                   // To simplify: all initialPos are defined in a conceptual [0,1]x[0,1] square, then scaled.
        if (i == 3) initialPos = float2(0.6, 0.6) * float2(xMax, yMax); // Corrected for consistency.

        // Calculate current position based on initial position, velocity, and time.
        blobs[i].position = initialPos + blobs[i].velocity * time;

        // Implement a basic "bounce" or "wrap-around" effect using fmod (modulo).
        // This creates a continuous, periodic motion within the defined bounds.
        // The blob "disappears" on one side and "reappears" on the opposite.
        // Effective radius is used to make the wrap happen when the center is radius distance outside the boundary.
        float effectiveRadiusX = blobs[i].radius;
        blobs[i].position.x = fmod(blobs[i].position.x, xMax + effectiveRadiusX * 2.0);
        if (blobs[i].position.x < -effectiveRadiusX) blobs[i].position.x += (xMax + effectiveRadiusX * 2.0);

        float effectiveRadiusY = blobs[i].radius;
        blobs[i].position.y = fmod(blobs[i].position.y, yMax + effectiveRadiusY * 2.0);
        if (blobs[i].position.y < -effectiveRadiusY) blobs[i].position.y += (yMax + effectiveRadiusY * 2.0);
    }

    // Calculate pixel color based on metaball influences.
    float totalInfluence = 0.0; // Sum of influences from all blobs at the current pixel.
    float3 mixedColor = float3(0.0, 0.0, 0.0); // Accumulated color from blobs.

    for (int i = 0; i < 4; ++i) {
        // Calculate squared distance from the current pixel (aspectCorrectedUV) to the blob's center.
        float dx = aspectCorrectedUV.x - blobs[i].position.x;
        float dy = aspectCorrectedUV.y - blobs[i].position.y;
        float distSq = dx * dx + dy * dy;

        // Avoid division by zero or extremely high influence if distance is near zero.
        if (distSq < 0.00001) distSq = 0.00001;

        // Metaball influence formula: radius^2 / distance_squared.
        // This creates a field that falls off with distance.
        float influence = (blobs[i].radius * blobs[i].radius) / distSq;
        totalInfluence += influence;
        mixedColor += blobs[i].color * influence; // Weight blob color by its influence.
    }

    // Define background color for the "fluid".
    float3 backgroundColor = float3(0.1, 0.0, 0.2); // Dark blue/purple.
    float3 finalColor = backgroundColor;

    // Determine if the pixel is part of a "lava" blob based on total influence.
    float threshold = 1.0; // Threshold for metaball visibility. Tune this to change blob appearance.

    if (totalInfluence > threshold) {
        // If influence exceeds threshold, color the pixel as part of a metaball.
        // Normalize the mixedColor by totalInfluence to get a weighted average color.
        // Add a small epsilon to prevent division by zero if totalInfluence is zero (though unlikely here).
        mixedColor /= (totalInfluence + 0.001);
        // Mix the background color with the blob color using smoothstep for a softer transition.
        // The transition range (threshold - 0.1 to threshold + 0.5) can be tuned.
        finalColor = mix(backgroundColor, mixedColor, smoothstep(threshold - 0.1, threshold + 0.5, totalInfluence));
        // Optionally, brighten the color based on how much influence exceeds the threshold.
        finalColor = clamp(finalColor * (totalInfluence - threshold + 1.0), 0.0, 1.0);
    }

    return float4(finalColor, 1.0); // Return final pixel color with full opacity.
}
