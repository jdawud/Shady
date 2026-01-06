//
//  ShaderView12.swift
//  Shady
//
//  Created by Junaid Dawud on 11/25/24.
//
//  Interactive silvery liquid wave shader.

import SwiftUI
import MetalKit

// UIViewRepresentable for the interactive "Silvery Liquid" Metal shader view.
// This view renders an animated effect that responds to touch input.
struct TwelfthShaderView: UIViewRepresentable {
    // Binding to control animation state from the parent SwiftUI view.
    @Binding var isAnimating: Bool
    
    // Creates and configures the underlying MTKView.
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator // The coordinator handles drawing and Metal lifecycle.
        mtkView.preferredFramesPerSecond = 60 // Target frame rate.
        mtkView.enableSetNeedsDisplay = true // Allows optimized redrawing.
        mtkView.device = MTLCreateSystemDefaultDevice() // Sets the Metal device.
        mtkView.framebufferOnly = false // May be needed if the texture is processed post-render.
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // Background color.
        mtkView.drawableSize = mtkView.frame.size // Initial size setup.
        
        // Setup gesture recognizer for touch input.
        // The coordinator's handlePan method will be called on pan gestures.
        let gestureRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        mtkView.addGestureRecognizer(gestureRecognizer)
        
        return mtkView
    }
    
    // Updates the MTKView based on changes in SwiftUI state.
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Propagate the animation state to the coordinator and pause/resume the view.
        context.coordinator.isAnimating = isAnimating
        uiView.isPaused = !isAnimating
    }
    
    // Creates the Coordinator instance.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class: Handles Metal rendering, delegate methods, and gesture input.
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: TwelfthShaderView // Reference to the parent UIViewRepresentable.
        var device: MTLDevice! // Metal device (GPU).
        var commandQueue: MTLCommandQueue! // Queue for Metal commands.
        var pipelineState: MTLRenderPipelineState! // Compiled render pipeline state.
        var time: Float = 0 // Time uniform for animation.
        var isAnimating: Bool = true // Internal animation state.
        var touchLocation: CGPoint = .zero // Current touch location, updated by gesture recognizer.
        
        // Initializes the coordinator and sets up Metal resources.
        init(_ parent: TwelfthShaderView) {
            self.parent = parent
            super.init()
            
            // Ensure a Metal device is available.
            guard let device = MTLCreateSystemDefaultDevice() else { fatalError("GPU not available") }
            self.device = device
            
            // Create a command queue.
            commandQueue = device.makeCommandQueue()
            
            // Load shader functions from the default Metal library.
            guard let library = device.makeDefaultLibrary() else { fatalError("Unable to create default library") }
            guard let vertexFunction = library.makeFunction(name: "vertex_shader_12") else { fatalError("Unable to create vertex function") }
            guard let fragmentFunction = library.makeFunction(name: "fragment_shader_12") else { fatalError("Unable to create fragment function") }
            
            // Configure the render pipeline descriptor.
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // Pixel format for the output.
            
            // Create the render pipeline state.
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Unable to create pipeline state: \(error)")
            }
        }
        
        // Called when the MTKView's drawable size changes (e.g., due to rotation).
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Can be used to adjust resources or calculations based on the new size.
        }
        
        // Called for each frame to perform drawing operations.
        func draw(in view: MTKView) {
            // Ensure animation is active and all necessary Metal objects are available.
            guard isAnimating,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            // Increment time for animation, based on the view's frame rate.
            time += 1 / Float(view.preferredFramesPerSecond)
            
            // Vertices for a full-screen quad.
            let vertices: [Float] = [-1, -1, 1, -1, -1, 1, 1, 1]
            
            // Encode drawing commands.
            renderEncoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
            renderEncoder.setRenderPipelineState(pipelineState)
            
            // Prepare shader uniforms, including resolution, time, and touch location.
            // Note: touchLocation.y is inverted (view.bounds.height - touchLocation.y)
            // because Metal's fragment coordinate system often has (0,0) at the top-left,
            // while UIKit might have (0,0) at the bottom-left or top-left depending on context.
            // This inversion makes touch input align with visual output as expected.
            var uniforms = Uniforms12(
                resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
                time: time,
                touch: SIMD2<Float>(Float(touchLocation.x), Float(view.bounds.height - touchLocation.y)),
                padding: SIMD2<Float>(0, 0) // Padding for memory alignment if needed.
            )
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms12>.size, index: 0)
            
            // Draw the quad.
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            // Present the drawable and commit the command buffer for GPU execution.
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        // Objective-C exposed method to handle pan gesture updates.
        // Updates the touchLocation property used in the shader.
        @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            // Get the touch location within the MTKView.
            touchLocation = gestureRecognizer.location(in: gestureRecognizer.view)
            // No need to call setNeedsDisplay if enableSetNeedsDisplay is true and preferredFramesPerSecond > 0,
            // as MTKView will redraw automatically. If not, setNeedsDisplay() would be called here.
        }
    }
}

// Defines the structure for uniforms passed to the shader for TwelfthShaderView.
struct Uniforms12 {
    var resolution: SIMD2<Float>  // Viewport resolution (width, height).
    var time: Float               // Elapsed time for animation.
    var touch: SIMD2<Float>       // Current touch coordinates (x, y).
    var padding: SIMD2<Float>     // Padding to ensure memory alignment, if necessary.
}

/// Displays an interactive silvery liquid wave shader effect.
struct ShaderView12: View {
    @State private var isAnimating = true
    
    var body: some View {
        VStack {
            TwelfthShaderView(isAnimating: $isAnimating)
                .frame(height: 400)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            Toggle("Animate", isOn: $isAnimating)
                .padding()
        }
        .padding()
    }
}

