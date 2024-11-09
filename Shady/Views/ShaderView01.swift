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

    func setup() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device!.makeCommandQueue()

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = device!.makeDefaultLibrary()?.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = device!.makeDefaultLibrary()?.makeFunction(name: "fragment_main")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineDescriptor)

        self.colorPixelFormat = .bgra8Unorm
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor else { return }

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setRenderPipelineState(pipelineState)

        // Increment time to animate the background
        time += 0.016
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct FirstShaderView: View {
    var body: some View {
        ZStack {
            MetalBackgroundView() // Your first Metal shader background
                .edgesIgnoringSafeArea(.all)

            VStack {
                NavigationLink(destination: SecondShaderView()) {
                    Text("Metal!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct MetalBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView {
        return MetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView, context: Context) {}
}
