//
//  CarViewerView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import RealityKit
import SwiftUI

/// Live 3D preview of the robot-car. Built with the modern SwiftUI-native
/// `RealityView` (not the deprecated `ARView` + `ARKit` + `UIViewRepresentable`
/// stack used by the old reference). It renders a non-AR virtual scene, so it
/// works embedded in the editor layout with no camera-feed / world-tracking.
///
/// Drag to orbit, pinch to zoom. The car itself is rebuilt whenever the shared
/// `CarEditorModel` changes.
struct CarViewerView: View {
    let model: CarEditorModel

    /// Persistent root for the whole car. Lives for the view's lifetime; only
    /// its children (the car parts) are rebuilt when the config changes.
    @State private var holder = Entity()

    /// Orbit / zoom state, driven by gestures.
    @State private var yaw: Double = -0.5
    @State private var pitch: Double = -0.22
    @State private var zoom: Double = 1.0
    @State private var lastDrag: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0

    var body: some View {
        // Read the tracked model properties here so any change re-evaluates
        // `body`, which re-runs the RealityView `update` closure.
        let config = CarBuilder.Config(
            lengthCm: Float(model.lengthCm),
            widthCm: Float(model.widthCm),
            heightCm: Float(model.heightCm),
            bodyColor: model.bodyColor.color,
            bodyColorId: model.bodyColor.id,
            tyreIndex: tyres.firstIndex { $0.id == model.tyre.id } ?? 0
        )

        RealityView { content in
            content.add(holder)
            CarBuilder.apply(to: holder, config: config)
            applyTransform()
        } update: { _ in
            // `apply` is a no-op when the config is unchanged (e.g. during an
            // orbit drag), so this is cheap to run on every update.
            CarBuilder.apply(to: holder, config: config)
            applyTransform()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let dx = value.translation.width - lastDrag.width
                    let dy = value.translation.height - lastDrag.height
                    yaw -= Double(dx) * 0.012
                    pitch -= Double(dy) * 0.012
                    pitch = max(-1.2, min(1.2, pitch))
                    lastDrag = value.translation
                }
                .onEnded { _ in lastDrag = .zero }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    let m = value.magnification
                    zoom *= Double(m / lastMagnification)
                    zoom = max(0.45, min(2.5, zoom))
                    lastMagnification = m
                }
                .onEnded { _ in lastMagnification = 1.0 }
        )
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .bottom) {
            Text("Drag to rotate • Pinch to zoom")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)
        }
    }

    /// Apply orbit (yaw/pitch) and zoom to the car root.
    private func applyTransform() {
        let rotation = simd_quatf(angle: Float(yaw), axis: [0, 1, 0])
                    * simd_quatf(angle: Float(pitch), axis: [1, 0, 0])
        holder.transform = Transform(
            scale: SIMD3<Float>(repeating: Float(zoom)),
            rotation: rotation,
            translation: .zero
        )
    }
}

#Preview {
    CarViewerView(model: CarEditorModel())
        .frame(height: 360)
}
