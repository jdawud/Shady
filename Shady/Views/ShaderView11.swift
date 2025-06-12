//
//  ShaderView11.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

import SwiftUI
import MetalKit

class MetalView11: MTKView {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0 // Time uniform for animations.
    var displayLink: CADisplayLink? // CADisplayLink can be used for vsync-timed drawing loop.
    
    // Deinitializer to ensure proper cleanup of resources.
    deinit {
        cleanup()
    }
    
    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        self.device = device ?? MTLCreateSystemDefaultDevice() // Assign a Metal device.
        setup() // Perform initial Metal setup.
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice() // Assign a Metal device.
        setup() // Perform initial Metal setup.
    }
    
    // Releases Metal and display link resources.
    func cleanup() {
        isPaused = true // Pause the MTKView's rendering loop.
        displayLink?.invalidate() // Stop the display link.
        displayLink = nil
        commandQueue = nil // Release the command queue.
        pipelineState = nil // Release the pipeline state.
        // Releasing the device might be necessary if it's not shared or to signal completion.
        device = nil
        print("MetalView11 cleaned up") // For debugging
    }
    
    // Configures Metal resources: device, command queue, pipeline state.
    func setup() {
        guard let device = device else {
            fatalError("Metal is not supported on this device")
        }
        
        // Set the pixel format for the view.
        self.colorPixelFormat = .bgra8Unorm
        // Create a command queue for submitting rendering commands.
        commandQueue = device.makeCommandQueue()
        
        // Load the default shader library.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }
        
        // Load the vertex and fragment shader functions.
        guard let vertexFunction = library.makeFunction(name: "vertex_main11") else {
            fatalError("Failed to load vertex function 'vertex_main11'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main11") else {
            fatalError("Failed to load fragment function 'fragment_main11'")
        }
        
        // Create a render pipeline descriptor.
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
        // Note: CADisplayLink setup would typically happen here if a custom game loop is desired,
        // but MTKView handles its own display link when isPaused is false and enableSetNeedsDisplay is false.
        // If enableSetNeedsDisplay is true, draw() is called when setNeedsDisplay() is called.
    }
    
    // Called for each frame to draw the content.
    override func draw(_ rect: CGRect) {
        // Ensure Metal objects are available.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }
        
        // Set the background clear color.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        // Create a command buffer and render encoder.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        // Set the render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Update and pass 'time' uniform.
        time += 0.016 // Approx 60 FPS, though preferredFramesPerSecond is 30.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        // Calculate and pass 'resolution' uniform.
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        
        // Draw a full-screen quad.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // Finalize encoding and commit the command buffer.
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// UIViewRepresentable wrapper for MetalView11.
// Handles the integration and lifecycle of MetalView11 within SwiftUI.
struct MetalBackgroundView11: UIViewRepresentable {
    // Binding to control the active state from the parent SwiftUI view.
    @Binding var isActive: Bool
    
    // Creates the MetalView11 instance.
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalView11(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = true // Redraw on demand.
        mtkView.preferredFramesPerSecond = 30 // Set desired frame rate.
        mtkView.isPaused = !isActive // Set initial pause state.
        return mtkView
    }
    
    // Updates the MetalView11 when SwiftUI state changes.
    func updateUIView(_ uiView: MTKView, context: Context) {
        // If the view should no longer be active, trigger its cleanup.
        if !isActive {
            (uiView as? MetalView11)?.cleanup()
        }
        // Synchronize the paused state of the MTKView with the isActive binding.
        uiView.isPaused = !isActive
    }
    
    // Called when the view is removed from the SwiftUI hierarchy.
    // Ensures that Metal resources are properly released.
    static func dismantleUIView(_ uiView: MTKView, coordinator: ()) {
        print("MetalBackgroundView11 dismantling, cleaning up MetalView11.") // For debugging
        (uiView as? MetalView11)?.cleanup()
    }
}

// Displays the shader effect for view 11 of 12.
// This view manages the lifecycle of its Metal rendering through the `isActive` state.
struct ShaderView11: View {
    // Environment property to access presentation mode, useful for custom back navigation.
    // Currently not used directly in this simplified view structure but kept for potential future use.
    @Environment(\.presentationMode) var presentationMode
    // State variable to control the activity of the Metal view.
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            MetalBackgroundView11(isActive: $isActive)
                .edgesIgnoringSafeArea(.all)
            
            // Removed NavigationLink and related VStack
        }
        // When the view disappears (e.g., due to navigation), set `isActive` to false.
        // This signals `MetalBackgroundView11` to clean up resources.
        .onDisappear {
            print("ShaderView11 disappeared, setting isActive to false.") // For debugging
            isActive = false
        }
    }
}
