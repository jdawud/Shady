//
//  ContentView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

import SwiftUI

struct ContentView: View {
    // State variable to keep track of the current view.

    // Ranges from 0 to 14 (inclusive), corresponding to 15 different shader views.

    @State private var currentViewIndex: Int = 0

    var body: some View {
        VStack {

            // Conditionally display one of the 15 shader views

            // based on the current value of currentViewIndex.
            if currentViewIndex == 0 {
                ShaderView01()
            } else if currentViewIndex == 1 {
                ShaderView02()
            } else if currentViewIndex == 2 {
                ShaderView03()
            } else if currentViewIndex == 3 {
                ShaderView04()
            } else if currentViewIndex == 4 {
                ShaderView05()
            } else if currentViewIndex == 5 {
                ShaderView06()
            } else if currentViewIndex == 6 {
                ShaderView07()
            } else if currentViewIndex == 7 {
                ShaderView08()
            } else if currentViewIndex == 8 {
                ShaderView09()
            } else if currentViewIndex == 9 {
                ShaderView10()
            } else if currentViewIndex == 10 {
                ShaderView11()
            } else if currentViewIndex == 11 {
                ShaderView12()

            } else if currentViewIndex == 12 {
                ShaderView13()
            } else if currentViewIndex == 13 {
                ShaderView14()
            } else if currentViewIndex == 14 {
                ShaderView15()
            }

            Button("Next Shader") {
                // Increment the view index
                currentViewIndex += 1

                // If the index reaches 15 (for 15 views, 0-14), reset it to 0 to loop back to the first view
                if currentViewIndex == 15 {

                    currentViewIndex = 0
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
        }
    }
}


#Preview {
    ContentView()
}
