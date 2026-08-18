//
//  StructureCell.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct StructureCell: View {
    let dimension: Dimension
    @Binding var value: Double
    let minimum: Double
    
    @State private var stepIndex: Double = 0
    
    private var currentLevel: DimensionLevel {
        DimensionLevel(rawValue: Int(round(stepIndex))) ?? .low
    }
    
    private var minValidStepIndex: Double {
        let firstValid = DimensionLevel.allCases.first(where: { $0.valueInCm >= minimum })
        return Double(firstValid?.rawValue ?? DimensionLevel.high.rawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dimension.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(currentLevel.label(for: dimension)) (\(Int(value)) cm)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { stepIndex },
                    set: { newStep in
                        let clampedStep = max(round(newStep), minValidStepIndex)
                        if clampedStep != stepIndex {
                            stepIndex = clampedStep
                            if let level = DimensionLevel(rawValue: Int(clampedStep)) {
                                value = level.valueInCm
                            }
                        }
                    }
                ),
                in: 0...2,
                step: 1
            )
            
            HStack {
                ForEach(DimensionLevel.allCases) { level in
                    let isAvailable = level.valueInCm >= minimum
                    let isSelected = currentLevel == level
                    
                    Text(level.label(for: dimension))
                        .font(.caption2)
                        .foregroundStyle(
                            !isAvailable ? .tertiary :
                            isSelected ? .primary : .secondary
                        )
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    if level != DimensionLevel.allCases.last {
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: stepIndex)
        .onAppear {
            clampAndUpdate(to: value)
        }
        .onChange(of: minimum) { _, _ in
            clampAndUpdate(to: value)
        }
    }
    
    private func clampAndUpdate(to targetValue: Double) {
        let level = DimensionLevel.nearest(to: targetValue, minimum: minimum)
        stepIndex = Double(level.rawValue)
        value = level.valueInCm
    }
}
