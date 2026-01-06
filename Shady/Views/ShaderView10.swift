//
//  ShaderView10.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//
//  Raindrops on glass shader.

import SwiftUI
import MetalKit

class MetalView10: MTKView {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0 // Time uniform for shader animations.

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

        // Update and pass 'time' uniform for animation based on frame rate.
        time += 1.0 / Float(preferredFramesPerSecond)
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
struct MetalBackgroundView10: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalView10(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = 30
        mtkView.isPaused = false
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.setNeedsDisplay()
    }
}

/// Displays a raindrops on glass shader effect.
struct ShaderView10: View {
    var body: some View {
        MetalBackgroundView10()
            .edgesIgnoringSafeArea(.all)
    }
}
