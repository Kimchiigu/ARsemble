//
//  ContentView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 10/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SurfaceScannerView()
            .onAppear {
                SoundManager.shared.playBackgroundMusic(named: "music-bg")
            }
    }
}

#Preview {
    ContentView()
}
