//
//  SecondShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

import SwiftUI
import MetalKit

class MetalView2: MTKView {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        setup()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // Configures the Metal view for ShaderView02.
    func setup() {
        // Obtain the default Metal device.
        device = MTLCreateSystemDefaultDevice()
        // Create a command queue.
        commandQueue = device!.makeCommandQueue()

        // Create a render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        // Set the vertex and fragment shader functions (specific to ShaderView02).
        pipelineDescriptor.vertexFunction = device!.makeDefaultLibrary()?.makeFunction(name: "vertex_main2")
        pipelineDescriptor.fragmentFunction = device!.makeDefaultLibrary()?.makeFunction(name: "fragment_main2")
        // Set the pixel format for the color attachment.
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Create the render pipeline state.
        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineDescriptor)

        // Set the pixel format for the MTKView.
        self.colorPixelFormat = .bgra8Unorm
    }

    // Called for each frame to draw the content for ShaderView02.
    override func draw(_ rect: CGRect) {
        // Ensure drawable and render pass descriptor are available.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor else { return }

        // Set the clear color (background).
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create command buffer and render encoder.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Increment time uniform for animation.
        time += 0.016 // Approx 60 FPS
        // Pass 'time' to the fragment shader.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Draw a full-screen quad.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        // Finalize encoding.
        renderEncoder.endEncoding()

        // Present the drawable and commit the command buffer.
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// Displays the shader effect for view 2 of 12.
struct ShaderView02: View {
    var body: some View {
        ZStack {
            MetalBackgroundView2() // Embeds the Metal view for this shader.
                .edgesIgnoringSafeArea(.all)

            // Removed NavigationLink and related VStack
        }
    }
}

// UIViewRepresentable wrapper for MetalView2, used in ShaderView02.
struct MetalBackgroundView2: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView2 {
        // Create and return an instance of MetalView2.
        return MetalView2(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView2, context: Context) {}
}
