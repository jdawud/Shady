//
//  FirstShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 11/8/24.
//

import SwiftUI
import MetalKit

class MetalView: MTKView {
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

    // Configures the Metal view, including device, command queue, and render pipeline.
    func setup() {
        // Obtain the default Metal device.
        device = MTLCreateSystemDefaultDevice()
        // Create a command queue to send commands to the GPU.
        commandQueue = device!.makeCommandQueue()

        // Create a render pipeline descriptor to configure the rendering pipeline.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        // Set the vertex and fragment shader functions from the default Metal library.
        pipelineDescriptor.vertexFunction = device!.makeDefaultLibrary()?.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = device!.makeDefaultLibrary()?.makeFunction(name: "fragment_main")
        // Set the pixel format for the color attachment (the output texture).
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Create the render pipeline state object.
        // This object contains the compiled shaders and pipeline configuration.
        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineDescriptor)

        // Set the pixel format for the MTKView itself.
        self.colorPixelFormat = .bgra8Unorm
    }

    // Called for each frame to draw the content of the view.
    override func draw(_ rect: CGRect) {
        // Ensure that a drawable and render pass descriptor are available.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor else { return }

        // Set the clear color for the render pass (background color).
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create a command buffer to hold the rendering commands.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        // Create a render encoder to encode rendering commands into the buffer.
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the previously created render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Increment time uniform to animate the shader.
        time += 0.016 // Approximately 60 FPS (1/60)
        // Pass the 'time' variable to the fragment shader at buffer index 0.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Draw a full-screen quad using a triangle strip.
        // This typically involves 4 vertices to cover the screen for shader effects.
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        // Finalize encoding of rendering commands.
        renderEncoder.endEncoding()

        // Present the drawable (the rendered image) to the screen.
        commandBuffer.present(drawable)
        // Commit the command buffer to the GPU for execution.
        commandBuffer.commit()
    }
}

// Displays the shader effect for view 1 of 12.
struct ShaderView01: View {
    var body: some View {
        ZStack {
            MetalBackgroundView() // Embeds the Metal view for shader rendering.
                .edgesIgnoringSafeArea(.all)

            // Removed NavigationLink and related VStack
        }
    }
}

// A UIViewRepresentable struct that wraps the MetalView (MTKView)
// to allow its use within a SwiftUI view hierarchy.
struct MetalBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView {
        // Create and return an instance of the custom MetalView.
        return MetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView, context: Context) {}
}
