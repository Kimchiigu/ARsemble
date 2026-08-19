//
//  ARsembleApp.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 10/08/26.
//

import SwiftUI

@main
struct ARsembleApp: App {

    /// DEBUG ENTRY POINT.
    ///
    /// Flip this to `true` to launch straight into the AR scanner
    /// (`SurfaceScannerView`) and bypass the whole Router navigation flow —
    /// handy for testing the AR experience without clicking through
    /// level → novel → concept → step → editor every time.
    ///
    /// It spawns the placeholder car (no editor spec), so you land directly on
    /// surface scanning. Set back to `false` to restore the normal app flow.
    /// The Router navigation stack is left completely intact either way.
    private let launchARDirectly = false

    /// Stored, not created inline in `body`: a `Router()` built inside the
    /// view builder is a brand-new object on every body evaluation, so any
    /// `router.pop()` from the debug entry point would silently do nothing.
    @State private var debugRouter = Router()

    var body: some Scene {
        WindowGroup {
            if launchARDirectly {
                // Router is still provided so any child that reads it (e.g. the
                // summary page's "Rebuild") doesn't crash during the test.
                SurfaceScannerView()
                    .environment(debugRouter)
            } else {
                ContentView()
            }
        }
    }
}
