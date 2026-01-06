//
//  ContentView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//
//  Main navigation view for the Shady shader playground.
//  Uses a simple carousel model: tap "Next Shader" to cycle through
//  16 Metal shader effects. Each effect is a self-contained SwiftUI view
//  wrapping an MTKView subclass with its own vertex/fragment shaders.
//

import SwiftUI

/// Main container view that manages navigation between shader effects.
/// Displays one shader at a time with a button to cycle to the next effect.
struct ContentView: View {
    /// Total number of shader views available in the app.
    private let shaderCount = 16
    
    /// Current shader view index (0 to shaderCount-1).
    @State private var currentViewIndex: Int = 0

    var body: some View {
        VStack {
            // Display the currently selected shader view
            currentShaderView
            
            Button("Next Shader") {
                currentViewIndex = (currentViewIndex + 1) % shaderCount
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
        }
    }
    
    /// Returns the appropriate shader view based on current index.
    @ViewBuilder
    private var currentShaderView: some View {
        switch currentViewIndex {
        case 0:  ShaderView01()
        case 1:  ShaderView02()
        case 2:  ShaderView03()
        case 3:  ShaderView04()
        case 4:  ShaderView05()
        case 5:  ShaderView06()
        case 6:  ShaderView07()
        case 7:  ShaderView08()
        case 8:  ShaderView09()
        case 9:  ShaderView10()
        case 10: ShaderView11()
        case 11: ShaderView12()
        case 12: ShaderView13()
        case 13: ShaderView14()
        case 14: ShaderView15()
        case 15: ShaderView16()
        default: ShaderView01()
        }
    }
}

#Preview {
    ContentView()
}
