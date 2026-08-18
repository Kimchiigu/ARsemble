//
//  CarViewerView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import RealityKit
import SwiftUI

struct CarViewerView: View {
    let viewModel: EditorViewModel
    var isPresenting: Bool = false

    @State private var holder = Entity()
    @State private var lighting = Entity()
    @State private var yaw: Double = -0.5
    @State private var pitch: Double = -0.22
    @State private var zoom: Double = 1.0
    @State private var lastDrag: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0

    private static var systemsRegistered = false

    var body: some View {
        RealityView { content in
            if !Self.systemsRegistered {
                CarAssemblySystem.registerSystem()
                Self.systemsRegistered = true
            }

            buildLighting(into: lighting)

            if !content.entities.contains(where: { $0 === holder }) {
                content.add(holder)
            }
            if !content.entities.contains(where: { $0 === lighting }) {
                content.add(lighting)
            }

            await CarBuilder.prepareWheelAssets()
            applySpec()
            CarBuilder.invalidateBuildState(on: holder)
            applyTransform()
        } update: { _ in
            applySpec()
            if !isPresenting { applyTransform() }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !isPresenting else { return }
                    let dx = value.translation.width - lastDrag.width
                    let dy = value.translation.height - lastDrag.height
                    yaw += Double(dx) * 0.012
                    pitch += Double(dy) * 0.012
                    pitch = max(-1.2, min(1.2, pitch))
                    lastDrag = value.translation
                }
                .onEnded { _ in lastDrag = .zero }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    guard !isPresenting else { return }
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
            if !isPresenting {
                Text("Drag to rotate • Pinch to zoom")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
            }
        }
        .onChange(of: isPresenting) { _, presenting in
            if presenting {
                playCinematic()
            } else {
                applyTransform()
            }
        }
    }

    private func applySpec() {
        holder.components[CarSpecComponent.self] = viewModel.carSpec
    }

    private func buildLighting(into root: Entity) {
        guard root.children.isEmpty else { return }

        let key = Entity()
        key.components[DirectionalLightComponent.self] = DirectionalLightComponent(
            color: UIColor.white, intensity: 2400, isRealWorldProxy: false
        )
        key.look(at: [0, 0, 0], from: [1.4, 2.6, 2.2], relativeTo: nil)
        root.addChild(key)

        let fill = Entity()
        fill.components[DirectionalLightComponent.self] = DirectionalLightComponent(
            color: UIColor(white: 0.88, alpha: 1), intensity: 750, isRealWorldProxy: false
        )
        fill.look(at: [0, 0, 0], from: [-1.8, 1.4, -1.6], relativeTo: nil)
        root.addChild(fill)
    }

    private func applyTransform() {
        let rotation = simd_quatf(angle: Float(yaw), axis: [0, 1, 0])
                    * simd_quatf(angle: Float(pitch), axis: [1, 0, 0])
        holder.transform = Transform(
            scale: SIMD3<Float>(repeating: Float(zoom)),
            rotation: rotation,
            translation: .zero
        )
    }

    private func playCinematic() {
        let facing = simd_quatf(angle: -Float.pi / 2, axis: [0, 1, 0])

        holder.move(
            to: Transform(scale: SIMD3<Float>(repeating: 1),
                          rotation: facing,
                          translation: .zero),
            relativeTo: nil,
            duration: 0.6,
            timingFunction: .easeInOut
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            if Task.isCancelled { return }
            holder.move(
                to: Transform(scale: SIMD3<Float>(repeating: 5),
                              rotation: facing,
                              translation: SIMD3<Float>(0, 0, 0.3)),
                relativeTo: nil,
                duration: 0.6,
                timingFunction: .easeIn
            )
        }
    }
}

#Preview {
    CarViewerView(viewModel: EditorViewModel())
        .frame(height: 360)
}
