//
//  CarEditorModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import Foundation
import Observation

/// Single source of truth for the robot-car editor. It drives both the 3D
/// viewer (`CarViewerView`) and every configuration panel (structure / tyre /
/// colour), so changing a value here instantly updates the 3D car.
///
/// Uses `@Observable` so any SwiftUI view that reads a property re-renders
/// automatically when it changes — no `@State` duplication or manual bindings
/// threaded between siblings.
@Observable
final class CarEditorModel {

    // MARK: Structure (centimetres — matches the 5...30 slider range)

    /// Length of the body, front → back.
    var lengthCm: Double
    /// Width of the body, side → side.
    var widthCm: Double
    /// Height of the body, floor → roof.
    var heightCm: Double

    // MARK: Appearance

    /// Body colour palette.
    var bodyColor: ColorPallete

    /// Tyre type — applied to all four wheels (a single, kid-simple choice).
    var tyre: Tyre

    init(
        lengthCm: Double = 18,
        widthCm: Double = 12,
        heightCm: Double = 9,
        bodyColor: ColorPallete = colorPalletes[4], // "Blue"
        tyre: Tyre = tyres[0]
    ) {
        self.lengthCm = lengthCm
        self.widthCm = widthCm
        self.heightCm = heightCm
        self.bodyColor = bodyColor
        self.tyre = tyre
    }

    /// Restore the starting robot-car.
    func reset() {
        lengthCm = 18
        widthCm = 12
        heightCm = 9
        bodyColor = colorPalletes[4]
        tyre = tyres[0]
    }
}
