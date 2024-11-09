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

        // Set pixel format before anything else
        self.colorPixelFormat = .bgra8Unorm
        
        commandQueue = device.makeCommandQueue()
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }

        // Load vertex and fragment functions
        guard let vertexFunction = library.makeFunction(name: "vertex_main5") else {
            fatalError("Failed to load vertex function 'vertex_main5'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main5") else {
            fatalError("Failed to load fragment function 'fragment_main5'")
        }

        // Setup pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set pipeline state and increment time
        renderEncoder.setRenderPipelineState(pipelineState)

        time += 0.016
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Define and set the resolution (view size in pixels)
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

        // Ensure the vertex data is properly set and encoded before drawing
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        renderEncoder.endEncoding()
        
        // Commit and present the buffer
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct FifthShaderView: View {
    var body: some View {
        ZStack {
            MetalBackgroundView5() // Fifth Metal shader background
                .edgesIgnoringSafeArea(.all)

            VStack {
                NavigationLink(destination: SixthShaderView()) {
                    Text("Lava Lamp!")
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

struct MetalBackgroundView5: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalView5 {
        return MetalView5(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }

    func updateUIView(_ uiView: MetalView5, context: Context) {}
}
