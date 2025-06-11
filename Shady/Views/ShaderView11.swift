//
//  ShaderView11.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

import SwiftUI
import MetalKit

class MetalView11: MTKView {
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0
    var displayLink: CADisplayLink?
    
    deinit {
        cleanup()
    }
    
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
    
    func cleanup() {
        displayLink?.invalidate()
        displayLink = nil
        commandQueue = nil
        pipelineState = nil
        device = nil
    }
    
    func setup() {
        guard let device = device else {
            fatalError("Metal is not supported on this device")
        }
        
        self.colorPixelFormat = .bgra8Unorm
        commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "vertex_main11") else {
            fatalError("Failed to load vertex function 'vertex_main11'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main11") else {
            fatalError("Failed to load fragment function 'fragment_main11'")
        }
        
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
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        time += 0.016
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct MetalBackgroundView11: UIViewRepresentable {
    @Binding var isActive: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalView11(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = 30
        mtkView.isPaused = false
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        if !isActive {
            (uiView as? MetalView11)?.cleanup()
        }
    }
    
    static func dismantleUIView(_ uiView: MTKView, coordinator: ()) {
        (uiView as? MetalView11)?.cleanup()
    }
}

struct EleventhShaderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            MetalBackgroundView11(isActive: $isActive)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                NavigationLink(destination: TwelfthShaderView(isAnimating: $isActive)) {
                    Text("Rainy Window!")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
            }
        }
        .onDisappear {
            isActive = false
        }
    }
}
