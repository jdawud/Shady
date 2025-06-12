//
//  FourthShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

import SwiftUI
import MetalKit

class MetalView4: MTKView {
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

        // Set pixel format for the MTKView. This must be done before creating the pipeline state.
        self.colorPixelFormat = .bgra8Unorm
        
        // Create a command queue to send commands to the GPU.
        commandQueue = device.makeCommandQueue()

        // Access the default shader library to load shader functions.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }

        // Load the vertex shader function from the library.
        guard let vertexFunction = library.makeFunction(name: "vertex_main4") else {
            fatalError("Failed to load vertex function 'vertex_main4'")
        }
        // Load the fragment shader function from the library.
        guard let fragmentFunction = library.makeFunction(name: "fragment_main4") else {
            fatalError("Failed to load fragment function 'fragment_main4'")
        }

        // Configure the render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Set the pixel format of the color attachment (output texture).
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Create the render pipeline state.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    // Called for each frame to draw the content for ShaderView04.
    override func draw(_ rect: CGRect) {
        // Ensure a drawable, render pass descriptor, and pipeline state are available.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }

        // Set the clear color for the render pass.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create a command buffer and a render command encoder.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the render pipeline state for the current rendering pass.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Increment the time uniform for animation effects.
        time += 0.016 // Approximately 60 FPS
        // Pass the 'time' variable to the fragment shader at buffer index 0.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Calculate the current resolution (drawable size) and pass it to the fragment shader.
        // This allows the shader to adapt to different screen sizes or view dimensions.
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        // Pass the 'resolution' variable to the fragment shader at buffer index 1.
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

        // Draw a full-screen quad (triangle strip with 4 vertices).
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize encoding of rendering commands.
        renderEncoder.endEncoding()
        
        // Present the drawable to the screen.
        commandBuffer.present(drawable)
        // Commit the command buffer for execution on the GPU.
        commandBuffer.commit()
    }
}

// Displays the shader effect for view 4 of 12.
struct ShaderView04: View {
    var body: some View {
        ZStack {
            MetalBackgroundView4() // Embeds the Metal view for this shader.
                .edgesIgnoringSafeArea(.all)

            // Removed NavigationLink and related VStack
        }
    }
}

// UIViewRepresentable wrapper for MetalView4, used in ShaderView04.
struct MetalBackgroundView4: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView4 {
        // Create and return an instance of MetalView4.
        return MetalView4(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView4, context: Context) {}
}



