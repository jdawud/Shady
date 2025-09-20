//
//  ShaderView15.swift
//  Shady
//
//  Created by OpenAI's ChatGPT on 24/7/24.
//  This file defines the SwiftUI view and Metal integration for the fifteenth shader,
//  which renders a dynamic, semi-realistic lightning bolt effect.
//

import SwiftUI
import MetalKit

struct ShaderView15: View {
    var body: some View {
        LightningMetalBackgroundView()
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
    }
}

struct LightningMetalBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> LightningMetalView {
        LightningMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: LightningMetalView, context: Context) {
        // No dynamic updates for now; parameters could be exposed here in the future.
    }
}

class LightningMetalView: MTKView, MTKViewDelegate {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!

    private var time: Float = 0.0
    private var resolution: simd_float2 = simd_float2(0, 0)

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? MTLCreateSystemDefaultDevice())
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }

        self.device = device
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1.0)
        self.delegate = self

        guard let queue = device.makeCommandQueue() else {
            fatalError("Unable to create Metal command queue for lightning shader.")
        }
        commandQueue = queue

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to load default Metal library for lightning shader.")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "LightningRenderPipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "lightningVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "lightningFragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create lightning pipeline state: \(error)")
        }

        preferredFramesPerSecond = 60
        framebufferOnly = true
        enableSetNeedsDisplay = false
        isPaused = false
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        resolution = simd_float2(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        time += 1.0 / Float(preferredFramesPerSecond)

        encoder.setRenderPipelineState(pipelineState)
        var localResolution = resolution
        var localTime = time
        encoder.setFragmentBytes(&localResolution, length: MemoryLayout<simd_float2>.size, index: 0)
        encoder.setFragmentBytes(&localTime, length: MemoryLayout<Float>.size, index: 1)

        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

#if DEBUG
struct ShaderView15_Previews: PreviewProvider {
    static var previews: some View {
        ShaderView15()
    }
}
#endif
