//
//  EditorViewModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 13/08/26.
//

import Foundation
import Observation

@Observable
final class EditorViewModel {
    enum ConfigTab: Hashable, CaseIterable {
        case structure, tyre, color

        var title: String {
            switch self {
            case .structure: "Structure"
            case .tyre: "Tyre"
            case .color: "Color"
            }
        }
    }

    var selectedTab: ConfigTab = .structure {
        didSet {
            if selectedTab != oldValue { previewedTyre = nil }
        }
    }

    var lengthCm: Double
    var widthCm: Double
    var heightCm: Double
    var bodyColor: ColorPallete
    var tyre: Tyre
    var previewedTyre: Tyre?

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

    func selectTyre(_ tyre: Tyre) {
        self.tyre = tyre
        previewedTyre = previewedTyre?.id == tyre.id ? nil : tyre
    }

    func selectColor(_ colorPallete: ColorPallete) {
        bodyColor = colorPallete
    }

    func reset() {
        lengthCm = 18
        widthCm = 12
        heightCm = 9
        bodyColor = colorPalletes[4]
        tyre = tyres[0]
        previewedTyre = nil
        selectedTab = .structure
    }
}
