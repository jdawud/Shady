//
//  ShaderView03.swift
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//
//  Metallic liquid distortion shader.

import SwiftUI
import MetalKit

class MetalView3: MTKView {
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

    /// Configures Metal device, command queue, and render pipeline.
    func setup() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device!.makeCommandQueue()

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = device!.makeDefaultLibrary()?.makeFunction(name: "vertex_main3")
        pipelineDescriptor.fragmentFunction = device!.makeDefaultLibrary()?.makeFunction(name: "fragment_main3")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        self.colorPixelFormat = .bgra8Unorm
    }

    /// Renders a frame with animated shader effect.
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor else { return }

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setRenderPipelineState(pipelineState)

        // Animate by incrementing time uniform based on frame rate
        time += 1.0 / Float(preferredFramesPerSecond)
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

/// Displays a metallic liquid distortion shader effect.
struct ShaderView03: View {
    var body: some View {
        MetalBackgroundView3()
            .edgesIgnoringSafeArea(.all)
    }
}

/// UIViewRepresentable wrapper for MetalView3.
struct MetalBackgroundView3: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView3 {
        return MetalView3(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView3, context: Context) {}
}
