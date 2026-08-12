//
//  CarEditorModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import Foundation
import Observation

@Observable
final class CarEditorModel {
    enum ConfigTab: Hashable, CaseIterable {
        case structure, tyre, color

        var title: String {
            switch self {
            case .structure: return "Structure"
            case .tyre:      return "Tyre"
            case .color:     return "Color"
            }
        }
    }

    var selectedTab: ConfigTab = .structure
    var lengthCm: Double
    var widthCm: Double
    var heightCm: Double
    var bodyColor: ColorPallete
    var tyre: Tyre

    init(
        lengthCm: Double = 18,
        widthCm: Double = 12,
        heightCm: Double = 9,
        bodyColor: ColorPallete = colorPalletes[4],
        tyre: Tyre = tyres[0]
    ) {
        self.lengthCm = lengthCm
        self.widthCm = widthCm
        self.heightCm = heightCm
        self.bodyColor = bodyColor
        self.tyre = tyre
    }

    func reset() {
        lengthCm = 18
        widthCm = 12
        heightCm = 9
        bodyColor = colorPalletes[4]
        tyre = tyres[0]
    }
}
