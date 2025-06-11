//
//  SilveryLiquidView.swift
//  Shady
//
//  Created by Junaid Dawud on 11/25/24.
//

import SwiftUI
import MetalKit

struct TwelfthShaderView: UIViewRepresentable {
    @Binding var isAnimating: Bool
    @State private var touchLocation: CGPoint = .zero
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.drawableSize = mtkView.frame.size
        
        let gestureRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        mtkView.addGestureRecognizer(gestureRecognizer)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.isAnimating = isAnimating
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: TwelfthShaderView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var time: Float = 0
        var isAnimating: Bool = true
        var touchLocation: CGPoint = .zero
        
        init(_ parent: TwelfthShaderView) {
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
            
            var uniforms = Uniforms(
                resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
                time: time,
                touch: SIMD2<Float>(Float(touchLocation.x), Float(view.bounds.height - touchLocation.y)),
                padding: SIMD2<Float>(0, 0)
            )
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            touchLocation = gestureRecognizer.location(in: gestureRecognizer.view)
        }
    }
}

struct Uniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var touch: SIMD2<Float>
    var padding: SIMD2<Float>
}

struct ShaderView12: View {
    @State private var isAnimating = true
    
    var body: some View {
        VStack {
            TwelfthShaderView(isAnimating: $isAnimating)
                .frame(height: 400)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            Toggle("Animate", isOn: $isAnimating)
                .padding()
        }
        .padding()
    }
}

