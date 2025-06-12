//
//  TenthShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

import SwiftUI
import MetalKit

class MetalView10: MTKView {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0 // Time uniform for shader animations.
    
    // Deinitializer to ensure Metal resources are released.
    deinit {
        cleanup()
    }
    
    // Releases Metal resources and pauses the view.
    // Important for preventing memory leaks when the view is no longer in use.
    func cleanup() {
        isPaused = true // Stop the rendering loop.
        // Release Metal objects by setting them to nil.
        commandQueue = nil
        pipelineState = nil
        // Setting device to nil is generally not needed if it's a shared system device,
        // but can be done if it was created specifically for this view.
        // Here, it implies this MTKView 'owns' its device instance or wants to signal it's done.
        device = nil
    }

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        self.device = device ?? MTLCreateSystemDefaultDevice()
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        setup()
    }

    func setup() {
        guard let device = device else {
            fatalError("Metal is not supported on this device")
        }

        // Set the pixel format of the MTKView.
        self.colorPixelFormat = .bgra8Unorm
        
        // Create a command queue.
        commandQueue = device.makeCommandQueue()

        // Load the default shader library.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }

        // Load specific shader functions for this view.
        guard let vertexFunction = library.makeFunction(name: "vertex_main10") else {
            fatalError("Failed to load vertex function 'vertex_main10'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main10") else {
            fatalError("Failed to load fragment function 'fragment_main10'")
        }

        // Configure the render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        // Create the render pipeline state.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    // Called for each frame to draw the view's content.
    override func draw(_ rect: CGRect) {
        // Ensure Metal objects are ready for drawing.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }

        // Set the background clear color.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create command buffer and render encoder.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Update and pass 'time' uniform for animation.
        time += 0.016 // Target approx 60 FPS, though preferredFramesPerSecond is 30 for this view.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Calculate and pass 'resolution' uniform.
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

        // Draw a full-screen quad.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize encoding.
        renderEncoder.endEncoding()
        
        // Present the drawable and commit the command buffer.
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// UIViewRepresentable wrapper for MetalView10.
// Manages the lifecycle of MetalView10, including resource cleanup.
struct MetalBackgroundView10: UIViewRepresentable {
    // Binding to control the active state of the Metal view from SwiftUI.
    @Binding var isActive: Bool
    
    // Creates the MetalView10 instance.
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalView10(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = true // Draw only when needed.
        mtkView.preferredFramesPerSecond = 30 // Specific frame rate for this view.
        mtkView.isPaused = !isActive // Initial pause state based on isActive.
        return mtkView
    }
    
    // Updates the MetalView10 based on state changes from SwiftUI.
    func updateUIView(_ uiView: MTKView, context: Context) {
        // If the view is no longer active (e.g., navigated away), trigger cleanup.
        if !isActive {
            (uiView as? MetalView10)?.cleanup()
        }
        // Sync the paused state with `isActive`.
        uiView.isPaused = !isActive
    }
    
    // Called when the UIViewRepresentable is removed from the view hierarchy.
    // Ensures Metal resources are released.
    static func dismantleUIView(_ uiView: MTKView, coordinator: ()) {
        print("MetalBackgroundView10 dismantling, cleaning up MetalView10.") // For debugging
        (uiView as? MetalView10)?.cleanup()
    }
}

// Displays the shader effect for view 10 of 12.
// Includes lifecycle management for Metal resources via the `isActive` state.
struct ShaderView10: View {
    // State to manage whether the Metal view and its animations are active.
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            MetalBackgroundView10(isActive: $isActive)
                .edgesIgnoringSafeArea(.all)
            
            // Removed NavigationLink and related VStack
        }
        // When the view disappears (e.g., navigated away from), set isActive to false.
        // This triggers cleanup in MetalBackgroundView10's updateUIView and eventually dismantleUIView.
        .onDisappear {
            print("ShaderView10 disappeared, setting isActive to false.") // For debugging
            isActive = false
        }
    }
}
