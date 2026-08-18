//
//  NextButton.swift
//  ARsemble
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

enum NextButtonStyle {
    case primary
    case secondary
}

struct NextButton: View {
    var title: String = "Next"
    var style: NextButtonStyle = .primary
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 28)
                .frame(minWidth: 185)
                .frame(height: 67)
                .background(backgroundColor)
                .cornerRadius(1000)
                .overlay(
                    RoundedRectangle(cornerRadius: 1000)
                        .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
                )
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .gray
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color("Primary")
        case .secondary: return Color("Secondary")
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return Color.gray.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        NextButton(title: "Next Step")
        NextButton(title: "Previous Step", style: .secondary)
    }
}
