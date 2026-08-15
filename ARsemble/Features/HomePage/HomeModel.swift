//
//  HomeModel.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import Foundation

struct HomeModel: Identifiable {
    let id = UUID()
    let lessonNumber: Int
    let title: String
    let imageName: String
    let levelCount: Int
    var isSuccessLevelCount: Int = 0
}
