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

    var selectedTab: ConfigTab = .structure

    var lengthCm: Double
    var widthCm: Double
    var heightCm: Double
    var bodyColor: ColorPallete
    var tyre: Tyre

    var tyreIndex: Int {
        tyres.firstIndex { $0.id == tyre.id } ?? 0
    }

    var minLengthCm: Double {
        let raw = (2.0 * Double(tyres[tyreIndex].diameterMm) / 10.0).rounded(.up)
        return max(5.0, raw)
    }

    init(
        lengthCm: Double = 18,
        widthCm: Double = 12,
        heightCm: Double = 9,
        bodyColor: ColorPallete = colorPalletes[4],
        tyre: Tyre = tyres[1]
    ) {
        self.widthCm = widthCm
        self.heightCm = heightCm
        self.bodyColor = bodyColor
        self.tyre = tyre
        let minLen = max(5.0, (2.0 * Double(tyre.diameterMm) / 10.0).rounded(.up))
        self.lengthCm = max(lengthCm, minLen)
    }

    func selectTyre(_ tyre: Tyre) {
        SoundManager.shared.playSound(named: "click")
        self.tyre = tyre
        if lengthCm < minLengthCm {
            lengthCm = minLengthCm
        }
    }

    func selectColor(_ colorPallete: ColorPallete) {
        SoundManager.shared.playSound(named: "click")
        bodyColor = colorPallete
    }

    func reset() {
        SoundManager.shared.playSound(named: "click")
        tyre = tyres[1]
        lengthCm = max(18, minLengthCm)
        widthCm = 12
        heightCm = 9
        bodyColor = colorPalletes[4]
        selectedTab = .structure
    }
}
