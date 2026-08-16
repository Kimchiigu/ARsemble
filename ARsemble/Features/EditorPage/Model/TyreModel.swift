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
    Tyre(name: "Small", image: "tyre6img", diameterMm: 28, widthMm: 12),
    Tyre(name: "Regular", image: "tyre1img", diameterMm: 43.2, widthMm: 22),
    Tyre(name: "Medium", image: "tyre2img", diameterMm: 56, widthMm: 28),
    Tyre(name: "Large", image: "tyre3img", diameterMm: 94.8, widthMm: 42),
    Tyre(name: "Extra Large", image: "tyre4img", diameterMm: 105, widthMm: 60),
    Tyre(name: "Thin", image: "tyre5img", diameterMm: 81.6, widthMm: 13.6)
]
