//
//  TyreModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import Foundation

struct Tyre: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let image: String
    let stats: TyreStats
}

let tyres: [Tyre] = [
    Tyre(name: "Tyre 1", image: "tyre1img", stats: TyreStats(grip: 3, size: 2, speed: 2, weight: 2)),
    Tyre(name: "Tyre 2", image: "tyre2img", stats: TyreStats(grip: 3, size: 3, speed: 2, weight: 3)),
    Tyre(name: "Tyre 3", image: "tyre3img", stats: TyreStats(grip: 3, size: 4, speed: 3, weight: 4)),
    Tyre(name: "Tyre 4", image: "tyre4img", stats: TyreStats(grip: 4, size: 5, speed: 3, weight: 5)),
    Tyre(name: "Tyre 5", image: "tyre5img", stats: TyreStats(grip: 2, size: 4, speed: 3, weight: 2)),
    Tyre(name: "Tyre 6", image: "tyre6img", stats: TyreStats(grip: 1, size: 1, speed: 1, weight: 1))
]
