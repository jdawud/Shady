//
//  LavaLampView.swift
//  Shady
//
//  Created by Junaid Dawud on 11/5/24.
//

import SwiftUI
import MetalKit

struct StarView: UIViewRepresentable {
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
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
        var parent: StarView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var vertices: [Float] = [-1, -1, 1, -1, -1, 1, 1, 1]
        var time: Float = 0
        var isAnimating: Bool = true
        
        init(_ parent: StarView) {
            self.parent = parent
            super.init()
            
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                device = metalDevice
            }
            
            commandQueue = device.makeCommandQueue()
            
            let library = device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertexShader")
            let fragmentFunction = library?.makeFunction(name: "fragmentShader")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                print("Unable to create pipeline state: \(error)")
            }
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize if needed
        }
        
        func draw(in view: MTKView) {
            guard isAnimating,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            time += 1 / Float(view.preferredFramesPerSecond)
            
            let size = view.drawableSize
            var shaderData = ShaderData(resolution: SIMD2<Float>(Float(size.width), Float(size.height)), time: time, padding: 0)
            
            renderEncoder.setVertexBytes(&vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
            renderEncoder.setFragmentBytes(&shaderData, length: MemoryLayout<ShaderData>.size, index: 0)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// ShaderData struct to match Metal shader's memory layout
struct ShaderData {
    var resolution: SIMD2<Float>
    var time: Float
    var padding: Float
}

struct SixthShaderView: View {
    @State private var isAnimating = true
    
    var body: some View {
        ZStack {
            
            StarView(isAnimating: $isAnimating)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                NavigationLink(destination: SeventhShaderView()) {
                    Text("Star!")
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
