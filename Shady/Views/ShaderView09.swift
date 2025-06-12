//
//  NinthShaderView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/8/24.
//

import SwiftUI
import MetalKit

class MetalView9: MTKView {
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

        // Set the pixel format for the MTKView, crucial for color output.
        self.colorPixelFormat = .bgra8Unorm
        
        // Create a command queue for the Metal device.
        commandQueue = device.makeCommandQueue()

        // Access the default shader library included with the app.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default shader library")
        }

        // Load the vertex and fragment shader functions by their names.
        guard let vertexFunction = library.makeFunction(name: "vertex_main9") else {
            fatalError("Failed to load vertex function 'vertex_main9'")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragment_main9") else {
            fatalError("Failed to load fragment function 'fragment_main9'")
        }

        // Create and configure a render pipeline descriptor.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Match the color attachment's pixel format to the view's format.
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        // Compile the pipeline descriptor into a pipeline state object.
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    // This method is called for every frame that needs to be rendered.
    override func draw(_ rect: CGRect) {
        // Ensure that Metal can provide a drawable, a render pass descriptor, and that the pipeline state is valid.
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let pipelineState = pipelineState else { return }

        // Set the clear color when the render pass begins.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Create a command buffer for this frame's rendering commands.
        let commandBuffer = commandQueue.makeCommandBuffer()!
        // Create a render command encoder to encode commands into the buffer.
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set the compiled render pipeline state.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Increment the time uniform to create animation.
        time += 0.016 // Approximately 1/60th of a second.
        // Pass the 'time' value to the fragment shader at buffer index 0.
        renderEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)

        // Get the current view size (resolution) and pass it to the fragment shader.
        var resolution = SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height))
        // Pass the 'resolution' value to the fragment shader at buffer index 1.
        renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 1)

        // Draw a full-screen quad (triangle strip with 4 vertices).
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Finalize the encoding of drawing commands.
        renderEncoder.endEncoding()
        
        // Present the drawable (rendered texture) to the screen.
        commandBuffer.present(drawable)
        // Commit the command buffer to the GPU for execution.
        commandBuffer.commit()
    }
}

// UIViewRepresentable that wraps MetalView9 for use in SwiftUI.
// This facilitates embedding the Metal-rendered view within a SwiftUI layout.
struct MetalBackgroundView9: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalView9(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.enableSetNeedsDisplay = true // Optimizes rendering by drawing only when needed.
        mtkView.preferredFramesPerSecond = 60 // Sets the target frame rate.
        mtkView.isPaused = false // Ensures the rendering loop is active.
        return mtkView
    }

    // This function is called when data changes in SwiftUI that affects the view.
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.setNeedsDisplay() // Triggers a redraw of the MTKView.
    }
}

// Displays the shader effect for view 9 of 12.
struct ShaderView09: View {
    var body: some View {
        ZStack {
            MetalBackgroundView9() // The Metal-rendered background.
                .edgesIgnoringSafeArea(.all)

            // Removed NavigationLink and related VStack
        }
    }
}
