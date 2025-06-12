//
//  ShaderView13.swift
//  Shady
//
//  Created by Jules on 22/7/24
//  This file defines the SwiftUI View and Metal rendering setup for the 13th shader effect,
//  which displays animated, procedurally generated clouds.
//

import SwiftUI
import MetalKit

// ShaderView13: The main SwiftUI View for displaying the drifting clouds shader.
// This view embeds the Metal-rendered content and ensures it ignores safe area
// and does not display a navigation bar, providing a full-screen experience.
struct ShaderView13: View {
    var body: some View {
        CloudMetalBackgroundView()
            .edgesIgnoringSafeArea(.all) // Ensure the Metal view extends to screen edges.
            .navigationBarHidden(true) // Hide navigation bar if this view is part of a NavigationView.
    }
}

// CloudMetalBackgroundView: A UIViewRepresentable struct.
// Its role is to bridge the CloudMetalView (which is a subclass of MTKView, a UIKit component)
// into the SwiftUI view hierarchy, allowing Metal rendering within a SwiftUI app.
struct CloudMetalBackgroundView: UIViewRepresentable {
    // Creates the instance of CloudMetalView that will be managed by this representable.
    func makeUIView(context: Context) -> CloudMetalView {
        // Initialize CloudMetalView with the default system Metal device.
        return CloudMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    // Updates the underlying CloudMetalView when SwiftUI state changes.
    // For this version, there are no specific SwiftUI state updates propagated to the Metal view.
    func updateUIView(_ uiView: CloudMetalView, context: Context) {
        // No specific updates from SwiftUI state are needed for this basic cloud shader.
        // If, for example, cloud speed or color were configurable via SwiftUI,
        // those updates would be passed to `uiView` here.
    }
}

// CloudMetalView: An MTKView subclass responsible for rendering the cloud shader.
// It handles Metal setup, the draw loop, and delegate methods for MTKView.
class CloudMetalView: MTKView {
    var commandQueue: MTLCommandQueue!        // Queue for sending commands to the GPU.
    var pipelineState: MTLRenderPipelineState! // Compiled shaders and pipeline configuration.
    var time: Float = 0                        // Time uniform, incremented each frame for animation.
    var resolution: simd_float2 = simd_float2(0, 0) // Stores current drawable size for the shader.

    // Initializer for creating the view programmatically.
    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device ?? MTLCreateSystemDefaultDevice())
        commonInit() // Perform common setup tasks.
    }

    // Initializer for creating the view from a storyboard or XIB (required).
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit() // Perform common setup tasks.
    }

    // commonInit: Centralized setup logic for Metal and MTKView properties.
    private func commonInit() {
        // 1. Set up Metal Device:
        // Ensure a valid Metal device is available; otherwise, the app cannot render.
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device // Assign the device to the MTKView.

        // 2. Create Command Queue:
        // The command queue is used to submit command buffers to the GPU for execution.
        commandQueue = device.makeCommandQueue()

        // 3. Load Shaders and Create Pipeline State:
        // Access the default Metal shader library bundled with the app.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default Metal library. Check if Shaders13.metal is compiled and linked.")
        }
        // Load the vertex and fragment shader functions by their names defined in Shaders13.metal.
        let vertexFunction = library.makeFunction(name: "cloudVertexShader")
        let fragmentFunction = library.makeFunction(name: "cloudFragmentShader")

        // Create a render pipeline descriptor to configure the rendering pipeline.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "CloudRenderPipeline" // For debugging.
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Set the pixel format for the color attachment (output texture) to match the view's format.
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat // Default is .bgra8Unorm.

        // Create the render pipeline state object from the descriptor.
        // This compiles the shaders and configures the pipeline for efficient rendering.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state: \(error)")
        }

        // 4. Configure MTKView settings:
        // self.colorPixelFormat is already .bgra8Unorm by default for MTKView.
        // framebufferOnly = true is an optimization if the rendered texture (framebuffer)
        // doesn't need to be read from (e.g., for post-processing effects).
        self.framebufferOnly = true
        self.preferredFramesPerSecond = 60 // Target frame rate for animations.
        self.delegate = self // ERROR: Cannot assign value of type 'CloudMetalView' to type '(any MTKViewDelegate)?'
        // enableSetNeedsDisplay = false means the view will redraw continuously at preferredFramesPerSecond.
        // If true, redraws would only happen when setNeedsDisplay() is called.
        self.enableSetNeedsDisplay = false
        // isPaused = false ensures the rendering loop starts immediately upon view creation.
        self.isPaused = false
    }

    // MTKViewDelegate method: Called when the MTKView's drawable size (viewport) changes.
    // This is important for shaders that depend on the aspect ratio or resolution.
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { // ERRORS: Method does not override any method from its superclass AND Non-'@objc' method 'mtkView(_:drawableSizeWillChange:)' does not satisfy requirement of '@objc' protocol 'MTKViewDelegate'
        // Update the resolution uniform with the new size.
        // This ensures the shader can adapt to orientation changes or window resizing.
        resolution = simd_float2(Float(size.width), Float(size.height))
    }

    // MTKViewDelegate method: Called for each frame to be rendered.
    // This is the main rendering loop.
    override func draw(in view: MTKView) { // ERRORS: Method does not override any method from its superclass AND Non-'@objc' method 'draw(in:)' does not satisfy requirement of '@objc' protocol 'MTKViewDelegate'
        // Ensure a drawable (texture to render to), render pass descriptor,
        // command buffer, and render encoder can be created.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor, // Describes attachments for rendering.
              let commandBuffer = commandQueue.makeCommandBuffer(),   // Buffer for GPU commands.
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            // If any of these fail, skip rendering for this frame.
            return
        }
        renderEncoder.label = "CloudRenderEncoder" // For debugging in GPU frame captures.

        // Update time uniform for animation.
        // Incrementing by a fixed step based on preferredFramesPerSecond helps achieve
        // consistent animation speed regardless of actual frame rate fluctuations.
        time += 1.0 / Float(self.preferredFramesPerSecond)

        // Set the current render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Pass uniforms to the fragment shader:
        // - Resolution (simd_float2) is passed to buffer index 0.
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<simd_float2>.size, index: 0)
        // - Time (float) is passed to buffer index 1.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 1)

        // Draw a full-screen quad.
        // The vertex shader (`cloudVertexShader`) generates 4 vertices for a triangle strip
        // covering the screen. No separate vertex buffer is needed here.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize encoding of rendering commands for this pass.
        renderEncoder.endEncoding()
        // Schedule the drawable to be presented after the command buffer is committed.
        commandBuffer.present(drawable)
        // Commit the command buffer to the GPU for execution.
        commandBuffer.commit()
    }
}

// Preview provider for ShaderView13, useful for iterative development in Xcode Canvas.
#if DEBUG
struct ShaderView13_Previews: PreviewProvider {
    static var previews: some View {
        ShaderView13()
    }
}
#endif
