//
//  ShaderView14.swift
//  Shady
//
//  Created by Jules on 23/7/24
//  SwiftUI View and Metal setup for the Lava Lamp shader (ShaderView14).
//  This file defines the necessary components to integrate the Metal-based
//  lava lamp effect (Shaders14.metal) into a SwiftUI application.
//

import SwiftUI
import MetalKit

// ShaderView14: The main SwiftUI View that displays the lava lamp shader effect.
// It embeds the Metal-rendered view (`LavaMetalBackgroundView`) and ensures it
// fills the screen by ignoring safe area edges and hiding any navigation bar.
struct ShaderView14: View {
    var body: some View {
        LavaMetalBackgroundView()
            .edgesIgnoringSafeArea(.all) // Allows the Metal view to extend to the screen edges.
            .navigationBarHidden(true)   // Hides the navigation bar if this view is part of a NavigationView.
    }
}

// LavaMetalBackgroundView: A `UIViewRepresentable` struct.
// This acts as a bridge between SwiftUI and UIKit, allowing the `LavaMetalView` (an MTKView subclass)
// to be used within the SwiftUI view hierarchy.
struct LavaMetalBackgroundView: UIViewRepresentable {
    // Creates the `LavaMetalView` instance that will be managed by SwiftUI.
    func makeUIView(context: Context) -> LavaMetalView {
        // Initialize with the default system Metal device.
        return LavaMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    // Updates the `LavaMetalView` when SwiftUI state changes that affect it.
    // For this basic lava lamp implementation, no dynamic updates from SwiftUI are needed.
    // If parameters like blob colors or speed were controllable via SwiftUI,
    // they would be passed to `uiView` here.
    func updateUIView(_ uiView: LavaMetalView, context: Context) {
        // No specific updates required for this version.
    }
}

// LavaMetalView: An `MTKView` subclass for rendering the lava lamp shader.
// It conforms to `MTKViewDelegate` to handle the draw loop and drawable size changes.
class LavaMetalView: MTKView, MTKViewDelegate {
    var commandQueue: MTLCommandQueue!        // Queue for submitting Metal commands to the GPU.
    var pipelineState: MTLRenderPipelineState! // Compiled shaders and rendering pipeline configuration.
    var time: Float = 0.0                      // Time uniform, incremented each frame for animation.
    var resolution: simd_float2 = simd_float2(0, 0) // Stores current drawable size for the shader.

    // Standard initializer for creating the view programmatically.
    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device ?? MTLCreateSystemDefaultDevice())
        commonInit() // Perform common Metal and MTKView setup.
    }

    // Required initializer for creating the view from a storyboard or XIB.
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit() // Perform common Metal and MTKView setup.
    }

    // commonInit: Centralized setup for Metal objects and MTKView properties.
    private func commonInit() {
        // 1. Obtain Metal Device:
        // Ensures a Metal device is available for rendering.
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }
        self.device = device // Assign the Metal device to the MTKView.

        // 2. Set MTKViewDelegate:
        // This class will handle draw and resize callbacks.
        self.delegate = self

        // 3. Create Command Queue:
        // Used to enqueue command buffers for GPU execution.
        commandQueue = device.makeCommandQueue()

        // 4. Load Shaders and Create Pipeline State:
        // Access the default Metal library (compiled from .metal files in the project).
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default Metal library. Ensure Shaders14.metal is compiled and linked.")
        }
        // Load the vertex and fragment shader functions by their names defined in Shaders14.metal.
        let vertexFunction = library.makeFunction(name: "lavaLampVertexShader")
        let fragmentFunction = library.makeFunction(name: "lavaLampFragmentShader")

        // Configure the render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "LavaLampRenderPipeline" // Useful for debugging in GPU frame captures.
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Set the pixel format of the color attachment (output texture) to match the view's format.
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat // Typically .bgra8Unorm.

        // Create the render pipeline state from the descriptor.
        // This compiles the shaders and sets up the fixed-function state for the pipeline.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state for lava lamp: \(error)")
        }

        // 5. Configure MTKView Properties:
        self.preferredFramesPerSecond = 60 // Target frame rate for smooth animation.
        // enableSetNeedsDisplay = false causes the view to redraw continuously at preferredFramesPerSecond.
        // If true, setNeedsDisplay() would need to be called manually to trigger redraws.
        self.enableSetNeedsDisplay = false
        self.isPaused = false // Start the rendering loop immediately.
        // framebufferOnly = true is an optimization if the rendered texture isn't read from.
        self.framebufferOnly = true
    }

    // MTKViewDelegate method: Called when the MTKView's drawable size (viewport) changes.
    // This is crucial for shaders that need to adapt to screen orientation or window resizing.
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Update the resolution uniform with the new drawable size.
        // This allows the shader to correctly calculate aspect ratios and positions.
        resolution = simd_float2(Float(size.width), Float(size.height))
    }

    // MTKViewDelegate method: Called for each frame that needs to be rendered.
    // This is the core of the rendering loop.
    func draw(in view: MTKView) {
        // Ensure essential Metal objects are available for rendering this frame.
        guard let drawable = currentDrawable, // The texture to render into.
              let renderPassDescriptor = currentRenderPassDescriptor, // Describes rendering targets.
              let commandBuffer = commandQueue.makeCommandBuffer(),   // Buffer for GPU commands.
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            // If any are unavailable, skip rendering for this frame.
            return
        }
        renderEncoder.label = "LavaLampRenderEncoder" // For GPU frame debugging.

        // Update the time uniform for animation.
        // Incrementing by a fixed step related to frame rate helps achieve consistent animation speed.
        time += 1.0 / Float(self.preferredFramesPerSecond)

        // Update resolution in case the drawable size changed since the last frame.
        resolution = simd_float2(Float(view.drawableSize.width),
                                 Float(view.drawableSize.height))

        // Configure the render command encoder:
        // Set the compiled render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)
        // Pass uniforms to the fragment shader:
        // - Resolution (simd_float2) is sent to buffer at index 0.
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<simd_float2>.size, index: 0)
        // - Time (float) is sent to buffer at index 1.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 1)

        // Draw a full-screen quad using a triangle strip.
        // The vertex shader (`lavaLampVertexShader`) generates the 4 vertices.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize encoding of commands for this render pass.
        renderEncoder.endEncoding()
        // Schedule the drawable to be presented on screen after the command buffer is processed.
        commandBuffer.present(drawable)
        // Commit the command buffer to the GPU for execution.
        commandBuffer.commit()
    }
}

// Preview provider for ShaderView14, useful for development in Xcode's Canvas.
#if DEBUG
struct ShaderView14_Previews: PreviewProvider {
    static var previews: some View {
        ShaderView14()
    }
}
#endif
