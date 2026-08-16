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
    let diameterMm: Float
    let widthMm: Float
}

let tyres: [Tyre] = [
    Tyre(name: "Tyre 1", image: "tyre1img", diameterMm: 43.2, widthMm: 22),
    Tyre(name: "Tyre 2", image: "tyre2img", diameterMm: 56, widthMm: 28),
    Tyre(name: "Tyre 3", image: "tyre3img", diameterMm: 94.8, widthMm: 42),
    Tyre(name: "Tyre 4", image: "tyre4img", diameterMm: 105, widthMm: 60),
    Tyre(name: "Tyre 5", image: "tyre5img", diameterMm: 81.6, widthMm: 13.6),
    Tyre(name: "Tyre 6", image: "tyre6img", diameterMm: 14, widthMm: 6)
]
