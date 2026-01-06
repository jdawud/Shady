//
//  ShaderView07.swift
//  Shady
//
//  Created by Junaid Dawud on 11/8/24.
//
//  Northern lights noise effect shader.

import SwiftUI
import MetalKit

// UIViewRepresentable for the Northern Lights themed MTKView.
// This view uses Metal shaders to render an animated Northern Lights effect.
struct NorthernLightsView: UIViewRepresentable {
    // Binding to control animation from the parent SwiftUI view.
    @Binding var isAnimating: Bool
    
    // Creates the MTKView instance.
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator // Assigns the coordinator to handle delegate methods.
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true // Allows for manual redraw requests.
        mtkView.device = MTLCreateSystemDefaultDevice() // Sets the default Metal device.
        mtkView.framebufferOnly = false // Useful if the rendered texture needs to be accessed.
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // Background color.
        mtkView.drawableSize = mtkView.frame.size // Initialize drawable size.
        return mtkView
    }
    
    // Updates the MTKView when relevant state changes.
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.isAnimating = isAnimating // Sync animation state with the coordinator.
    }
    
    // Creates the coordinator responsible for Metal rendering logic.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class: Manages Metal resources and the rendering loop.
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: NorthernLightsView // Reference to the parent NorthernLightsView.
        var device: MTLDevice! // The GPU.
        var commandQueue: MTLCommandQueue! // Queue for GPU commands.
        var pipelineState: MTLRenderPipelineState! // Compiled shaders and pipeline configuration.
        var time: Float = 0 // Time uniform for shader animation.
        var isAnimating: Bool = true // Internal animation flag.
        
        // Initializes the coordinator and sets up Metal components.
        init(_ parent: NorthernLightsView) {
            self.parent = parent
            super.init()
            
            // Ensure a Metal device is available.
            guard let device = MTLCreateSystemDefaultDevice() else { fatalError("GPU not available") }
            self.device = device
            
            // Create a command queue.
            commandQueue = device.makeCommandQueue()
            
            // Load shader functions from the default library.
            guard let library = device.makeDefaultLibrary() else { fatalError("Unable to create default library") }
            guard let vertexFunction = library.makeFunction(name: "vertex_shader_07") else { fatalError("Unable to create vertex function") }
            guard let fragmentFunction = library.makeFunction(name: "fragment_shader_07") else { fatalError("Unable to create fragment function") }
            
            // Configure the render pipeline.
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // Output pixel format.
            
            // Create the render pipeline state.
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Unable to create pipeline state: \(error)")
            }
        }
        
        // Handles view resizing.
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Can be used to update resolution-dependent parameters.
        }
        
        // Executes the drawing commands for each frame.
        func draw(in view: MTKView) {
            // Check if animation is active and essential Metal objects are ready.
            guard isAnimating,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            // Update time for animation.
            time += 1 / Float(view.preferredFramesPerSecond)
            
            // Define vertices for a full-screen quad.
            let vertices: [Float] = [-1, -1, 1, -1, -1, 1, 1, 1]
            
            // Encode rendering commands.
            renderEncoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
            renderEncoder.setRenderPipelineState(pipelineState)
            
            // Prepare and set shader uniforms.
            var uniforms = Uniforms07(resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)), time: time, padding: 0)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms07>.size, index: 0)
            
            // Draw the quad.
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            // Present the rendered image and commit the command buffer.
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// Defines the structure for data passed as uniforms to the shader for NorthernLightsView.
struct Uniforms07 {
    var resolution: SIMD2<Float> // Viewport resolution.
    var time: Float              // Elapsed time for animation.
    var padding: Float           // Padding for memory alignment if necessary.
}

/// Displays a northern lights noise effect shader.
struct ShaderView07: View {
    @State private var isAnimating = true
    
    var body: some View {
        NorthernLightsView(isAnimating: $isAnimating)
            .edgesIgnoringSafeArea(.all)
    }
}
