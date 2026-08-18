//
//  StepModel.swift
//  ARsemble
//
//  Created by Catherine Danielle on 17/08/26.
//

import Foundation

struct Step: Identifiable {
    let id: UUID
    let title: String
    let desc: String
    let image: String
    let mascot: String?
    var fillsFrame: Bool = false
}
