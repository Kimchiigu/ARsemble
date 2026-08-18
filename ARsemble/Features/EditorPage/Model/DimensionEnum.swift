//
//  DimensionEnum.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import Foundation

enum Dimension: String, CaseIterable, Identifiable {
    case length = "Length"
    case width = "Width"
    case height = "Height"
    
    var id: Self { self }
}
