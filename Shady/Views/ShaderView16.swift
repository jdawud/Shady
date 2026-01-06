//
//  ShaderView16.swift
//  Shady
//
//  Warp drive / hyperspace starfield effect shader.
//  Simulates the Star Trek warp speed effect with stars
//  streaking toward a central vanishing point.
//

import SwiftUI
import MetalKit

/// Displays the warp drive hyperspace starfield effect.
struct ShaderView16: View {
    var body: some View {
        WarpMetalBackgroundView()
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
    }
}

/// UIViewRepresentable wrapper for WarpMetalView.
struct WarpMetalBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> WarpMetalView {
        return WarpMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }
    
    func updateUIView(_ uiView: WarpMetalView, context: Context) {
        // No dynamic updates needed
    }
}

/// MTKView subclass that renders the warp drive starfield effect.
class WarpMetalView: MTKView, MTKViewDelegate {
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
    
    /// Configures Metal device, command queue, and render pipeline.
    private func commonInit() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("🚀 Metal is not supported on this device")
        }
        
        self.device = device
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0.01, green: 0.02, blue: 0.05, alpha: 1.0)
        self.delegate = self
        
        // Create command queue
        guard let queue = device.makeCommandQueue() else {
            fatalError("🚀 Unable to create Metal command queue for warp shader")
        }
        commandQueue = queue
        
        // Load shader library
        guard let library = device.makeDefaultLibrary() else {
            fatalError("🚀 Unable to load default Metal library for warp shader")
        }
        
        // Create render pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "WarpDriveRenderPipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "warpVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "warpFragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("🚀 Failed to create warp pipeline state: \(error)")
        }
        
        // Configure rendering settings
        preferredFramesPerSecond = 60
        framebufferOnly = true
        enableSetNeedsDisplay = false
        isPaused = false
    }
    
    // MARK: - MTKViewDelegate
    
    /// Called when the drawable size changes (rotation, resize).
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        resolution = simd_float2(Float(size.width), Float(size.height))
    }
    
    /// Renders a frame of the warp drive effect.
    func draw(in view: MTKView) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        // Update time uniform for animation
        time += 1.0 / Float(preferredFramesPerSecond)
        
        // Encode render commands
        encoder.setRenderPipelineState(pipelineState)
        
        // Pass uniforms to fragment shader
        var localResolution = resolution
        var localTime = time
        encoder.setFragmentBytes(&localResolution, length: MemoryLayout<simd_float2>.size, index: 0)
        encoder.setFragmentBytes(&localTime, length: MemoryLayout<Float>.size, index: 1)
        
        // Draw full-screen quad
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

#if DEBUG
struct ShaderView16_Previews: PreviewProvider {
    static var previews: some View {
        ShaderView16()
    }
}
#endif
