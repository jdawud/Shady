//
//  NorthernLightsView.swift
//  Shady
//
//  Created by Junaid Dawud on 11/8/24.
//

import SwiftUI
import MetalKit

struct NorthernLightsView: UIViewRepresentable {
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.isAnimating = isAnimating
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: NorthernLightsView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var time: Float = 0
        var isAnimating: Bool = true
        
        init(_ parent: NorthernLightsView) {
            self.parent = parent
            super.init()
            
            guard let device = MTLCreateSystemDefaultDevice() else { fatalError("GPU not available") }
            self.device = device
            
            commandQueue = device.makeCommandQueue()
            
            guard let library = device.makeDefaultLibrary() else { fatalError("Unable to create default library") }
            guard let vertexFunction = library.makeFunction(name: "vertex_shader") else { fatalError("Unable to create vertex function") }
            guard let fragmentFunction = library.makeFunction(name: "fragment_shader") else { fatalError("Unable to create fragment function") }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Unable to create pipeline state: \(error)")
            }
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard isAnimating,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            time += 1 / Float(view.preferredFramesPerSecond)
            
            let vertices: [Float] = [-1, -1, 1, -1, -1, 1, 1, 1]
            
            renderEncoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
            renderEncoder.setRenderPipelineState(pipelineState)
            
            var uniforms = Uniforms(resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)), time: time, padding: 0)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

struct Uniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var padding: Float
}

struct SeventhShaderView: View {
    @State private var isAnimating = true
    
    var body: some View {
        ZStack {
            
            NorthernLightsView(isAnimating: $isAnimating)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                NavigationLink(destination: FirstShaderView()) {
                    Text("What am I?")
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



