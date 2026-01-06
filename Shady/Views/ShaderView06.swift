//
//  ShaderView06.swift
//  Shady
//
//  Created by Junaid Dawud on 11/5/24.
//
//  Glowing metaball star effect shader.

import SwiftUI
import MetalKit

// UIViewRepresentable for embedding the Star-themed MTKView within SwiftUI.
// This view renders a dynamic star-like visual effect using Metal shaders.
struct StarView: UIViewRepresentable {
    // Binding to control animation state from the parent SwiftUI view.
    @Binding var isAnimating: Bool
    
    // Creates the underlying MTKView instance.
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator // Sets the coordinator to handle MTKViewDelegate callbacks.
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true // Allows the view to be redrawn on demand.
        
        // Assign the default Metal device.
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false // Allows reading from the rendered texture if needed.
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // Background color.
        mtkView.drawableSize = mtkView.frame.size // Initialize drawable size.
        
        return mtkView
    }
    
    // Updates the MTKView when an animatable state changes.
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.isAnimating = isAnimating // Propagate animation state to the coordinator.
    }
    
    // Creates the coordinator instance that manages Metal rendering logic.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class handles Metal setup and rendering loop (MTKViewDelegate).
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: StarView // Reference to the parent StarView.
        var device: MTLDevice! // The Metal device (GPU).
        var commandQueue: MTLCommandQueue! // Queue for Metal commands.
        var pipelineState: MTLRenderPipelineState! // The render pipeline state.
        var vertices: [Float] = [-1, -1, 1, -1, -1, 1, 1, 1] // Vertices for a full-screen quad.
        var time: Float = 0 // Time uniform for shader animations.
        var isAnimating: Bool = true // Internal animation state.
        
        // Initializes the Coordinator and sets up Metal resources.
        init(_ parent: StarView) {
            self.parent = parent
            super.init()
            
            // Assign the default Metal device.
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                device = metalDevice
            }
            
            // Create a command queue.
            commandQueue = device.makeCommandQueue()
            
            // Load shader functions from the default Metal library.
            let library = device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertexShader06")
            let fragmentFunction = library?.makeFunction(name: "fragmentShader06")
            
            // Configure the render pipeline descriptor.
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // Pixel format of the output.
            
            // Create the render pipeline state.
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("⚠️ Unable to create pipeline state: \(error)")
            }
        }
        
        // Called when the MTKView's drawable size changes (e.g., on rotation).
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // This can be used to update aspect ratios or resolution-dependent resources.
        }
        
        // Called for every frame to draw the content.
        func draw(in view: MTKView) {
            // Ensure animation is active and essential Metal objects are available.
            guard isAnimating,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            // Increment time based on frame rate for consistent animation speed.
            time += 1 / Float(view.preferredFramesPerSecond)
            
            // Prepare shader data (resolution and time).
            let size = view.drawableSize
            var shaderData = ShaderData06(resolution: SIMD2<Float>(Float(size.width), Float(size.height)), time: time, padding: 0)
            
            // Encode rendering commands.
            // Set vertex data (for the quad).
            renderEncoder.setVertexBytes(&vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
            // Set fragment shader data (uniforms).
            renderEncoder.setFragmentBytes(&shaderData, length: MemoryLayout<ShaderData06>.size, index: 0)
            // Set the render pipeline state.
            renderEncoder.setRenderPipelineState(pipelineState)
            // Draw the primitives (a triangle strip forming a quad).
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            // Finalize encoding.
            renderEncoder.endEncoding()
            
            // Present the drawable to the screen and commit the command buffer.
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// ShaderData struct to match Metal shader's memory layout for uniforms.
// This typically includes data like resolution, time, mouse position, etc.
struct ShaderData06 {
    var resolution: SIMD2<Float> // Viewport resolution in pixels.
    var time: Float              // Time elapsed, for animations.
    var padding: Float           // Padding to ensure correct memory alignment if needed.
}

/// Displays a glowing metaball star effect shader.
struct ShaderView06: View {
    @State private var isAnimating = true
    
    var body: some View {
        StarView(isAnimating: $isAnimating)
            .edgesIgnoringSafeArea(.all)
    }
}
