//
//  TyreModel.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct ColorPallete: Identifiable, Equatable {
    let id: UUID = UUID()
    let name: String
    let color: Color
}

let colorPalletes: [ColorPallete] = [
    ColorPallete(name: "Red",     color: Color(red: 255/255, green: 57/255,  blue: 60/255)),
    ColorPallete(name: "Orange",  color: Color(red: 255/255, green: 141/255, blue: 40/255)),
    ColorPallete(name: "Yellow",  color: Color(red: 255/255, green: 204/255, blue: 2/255)),
    ColorPallete(name: "Green",   color: Color(red: 53/255,  green: 199/255, blue: 89/255)),
    ColorPallete(name: "Blue",    color: Color(red: 0/255,   green: 136/255, blue: 255/255)),
    ColorPallete(name: "Pink",    color: Color(red: 255/255, green: 108/255, blue: 137/255)),
    ColorPallete(name: "Purple",  color: Color(red: 97/255,  green: 85/255,  blue: 245/255)),
    ColorPallete(name: "Magenta", color: Color(red: 203/255, green: 48/255,  blue: 224/255)),
    ColorPallete(name: "Brown",   color: Color(red: 172/255, green: 127/255, blue: 94/255)),
    ColorPallete(name: "White",   color: Color(red: 255/255, green: 255/255, blue: 255/255)),
    ColorPallete(name: "Gray",    color: Color(red: 142/255, green: 142/255, blue: 147/255)),
    ColorPallete(name: "Black",   color: Color(red: 0/255,   green: 0/255,   blue: 0/255))
]
