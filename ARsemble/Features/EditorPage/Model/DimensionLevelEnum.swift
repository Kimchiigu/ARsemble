//
//  DimensionLevelEnum.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

enum DimensionLevel: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2
    
    var id: Int { rawValue }
    
    var valueInCm: Double {
        switch self {
        case .low: return 15.0
        case .medium: return 21.0
        case .high: return 27.0
        }
    }
    
    func label(for dimension: Dimension) -> String {
        switch dimension {
        case .length:
            switch self {
            case .low: return "Short"
            case .medium: return "Regular"
            case .high: return "Long"
            }
        case .width:
            switch self {
            case .low: return "Narrow"
            case .medium: return "Regular"
            case .high: return "Wide"
            }
        case .height:
            switch self {
            case .low: return "Short"
            case .medium: return "Regular"
            case .high: return "Tall"
            }
        }
    }
    
    static func nearest(to cmValue: Double, minimum: Double) -> DimensionLevel {
        let validLevels = DimensionLevel.allCases.filter { $0.valueInCm >= minimum }
        let candidatePool = validLevels.isEmpty ? DimensionLevel.allCases : validLevels
        return candidatePool.min(by: { abs($0.valueInCm - cmValue) < abs($1.valueInCm - cmValue) }) ?? .high
    }
}
