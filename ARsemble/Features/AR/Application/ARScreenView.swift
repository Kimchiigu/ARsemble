//
//  ARScreenView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 12/08/26.
//

import SwiftUI
struct SurfaceScannerView: View {

    /// Owns the ARSession + scanRoot entity and publishes UI state.
    @StateObject private var driver = SurfaceScanDriver()

    var body: some View {

        ZStack(alignment: .bottom) {

            ARContainer(driver: driver)
                .ignoresSafeArea()


            controls
                .padding(.bottom, 28)
        }
    }


    // MARK: - Controls

    private var controls: some View {

        VStack(spacing: 12) {

            Text(driver.statusText)
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    .ultraThinMaterial,
                    in: Capsule()
                )


            HStack(spacing: 16) {

                Button("Rescan") {

                    driver.restartScan()
                }
                .buttonStyle(.borderedProminent)


                // Only show this when a surface has been locked.
                if driver.hasLockedSurface &&
                    !driver.targetLocked {

                    Text("Tap an object to select it")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            .ultraThinMaterial,
                            in: Capsule()
                        )
                }
            }
        }
    }
}



#Preview {
    SurfaceScannerView()
}
