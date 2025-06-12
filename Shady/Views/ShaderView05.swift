//
//  FifthShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

import SwiftUI
import MetalKit

class MetalView5: MTKView {
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

        // Set pixel format for the MTKView.
        self.colorPixelFormat = .bgra8Unorm
        
        // Create a command queue.
        commandQueue = device.makeCommandQueue()

        // Access the default shader library.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }

        // Load vertex and fragment shader functions for this specific view.
        guard let vertexFunction = library.makeFunction(name: "vertex_main5") else {
            fatalError("Failed to load vertex function 'vertex_main5'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main5") else {
            fatalError("Failed to load fragment function 'fragment_main5'")
        }

        // Configure the render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Create the render pipeline state.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    // Called for each frame to draw the content for ShaderView05.
    override func draw(_ rect: CGRect) {
        // Ensure necessary Metal objects are available.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }

        // Set the background clear color.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create command buffer and render encoder.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the current render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Update time for animation.
        time += 0.016 // Approx 60 FPS
        // Pass time to the fragment shader (buffer index 0).
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Get current drawable size for resolution.
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        // Pass resolution to the fragment shader (buffer index 1).
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

        // Draw a full-screen quad.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize encoding.
        renderEncoder.endEncoding()
        
        // Present the drawable and commit the buffer.
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// Displays the shader effect for view 5 of 12.
struct ShaderView05: View {
    var body: some View {
        ZStack {
            MetalBackgroundView5() // Embeds the Metal view for this shader.
                .edgesIgnoringSafeArea(.all)

            // Removed NavigationLink and related VStack
        }
    }
}

// UIViewRepresentable wrapper for MetalView5, used in ShaderView05.
struct MetalBackgroundView5: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView5 {
        // Create and return an instance of MetalView5.
        return MetalView5(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView5, context: Context) {}
}
