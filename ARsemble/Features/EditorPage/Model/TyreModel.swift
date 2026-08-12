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
}

let tyres: [Tyre] = [
    Tyre(name: "Tyre 1", image: "car.fill"),
    Tyre(name: "Tyre 2", image: "car.fill"),
    Tyre(name: "Tyre 3", image: "car.fill"),
    Tyre(name: "Tyre 4", image: "car.fill"),
    Tyre(name: "Tyre 5", image: "car.fill"),
    Tyre(name: "Tyre 6", image: "car.fill")
]
