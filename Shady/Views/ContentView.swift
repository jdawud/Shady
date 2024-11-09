//
//  ContentView.swift
//  Shady
//
//  Created by Junaid Dawud on 10/7/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {

            NavigationLink(destination: FirstShaderView()) {
                Text("press me!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
    }
}


#Preview {
    ContentView()
}
