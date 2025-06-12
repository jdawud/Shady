//
//  EighthShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

import SwiftUI
import MetalKit

class MetalView8: MTKView {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0

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

        // Set the pixel format for the MTKView.
        self.colorPixelFormat = .bgra8Unorm
        
        // Create a command queue for submitting work to the GPU.
        commandQueue = device.makeCommandQueue()

        // Load the shader library.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }

        // Load the specific vertex and fragment shader functions for this view.
        guard let vertexFunction = library.makeFunction(name: "vertex_main8") else {
            fatalError("Failed to load vertex function 'vertex_main8'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main8") else {
            fatalError("Failed to load fragment function 'fragment_main8'")
        }

        // Configure the render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat // Output format.

        // Create the render pipeline state.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    // Called each frame to render the view's content.
    override func draw(_ rect: CGRect) {
        // Ensure essential Metal objects are available.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }

        // Set the clear color for the background.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create a command buffer and render encoder.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the current render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Update and pass the 'time' uniform for animation.
        time += 0.016 // Approximately 60 FPS.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Calculate and pass the 'resolution' uniform (drawable size).
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

        // Draw a full-screen quad using a triangle strip.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize encoding.
        renderEncoder.endEncoding()
        
        // Present the drawable to the screen.
        commandBuffer.present(drawable)
        // Commit the command buffer to the GPU.
        commandBuffer.commit()
    }
}

// UIViewRepresentable wrapper for MetalView8.
// This allows MetalView8 to be used within the SwiftUI view hierarchy.
struct MetalBackgroundView8: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalView8(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = true // Allow on-demand redrawing.
        mtkView.preferredFramesPerSecond = 60 // Target frame rate.
        mtkView.isPaused = false // Ensure the view is not paused.
        return mtkView
    }

    // Called when the view needs to be updated from SwiftUI.
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.setNeedsDisplay() // Request a redraw.
    }
}

// Displays the shader effect for view 8 of 12.
struct ShaderView08: View {
    var body: some View {
        ZStack {
            MetalBackgroundView8() // Embeds the Metal view.
                .edgesIgnoringSafeArea(.all)

            // Removed NavigationLink and related VStack
        }
    }
}
