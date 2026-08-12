//
//  CarViewerView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import RealityKit
import SwiftUI

struct CarViewerView: View {
    let model: CarEditorModel

    @Binding var previewedTyre: Tyre?
    @State private var holder = Entity()
    
    @State private var lighting = Entity()
    @State private var yaw: Double = -0.5
    @State private var pitch: Double = -0.22
    @State private var zoom: Double = 1.0
    @State private var lastDrag: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0

    var body: some View {
        let config = CarBuilder.Config(
            lengthCm: Float(model.lengthCm),
            widthCm: Float(model.widthCm),
            heightCm: Float(model.heightCm),
            bodyColor: model.bodyColor.color,
            bodyColorId: model.bodyColor.id,
            tyreIndex: tyres.firstIndex { $0.id == model.tyre.id } ?? 0
        )

        RealityView { content in
            buildLighting(into: lighting)
            
            if !content.entities.contains(where: { $0 === holder }) {
                content.add(holder)
            }
            if !content.entities.contains(where: { $0 === lighting }) {
                content.add(lighting)
            }
            CarBuilder.apply(to: holder, config: config)
            applyTransform()
        } update: { _ in
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
        .overlay(alignment: .top) {
            if let tyre = previewedTyre {
                TyreStatView(name: tyre.name, stats: tyre.stats)
                    .shadow(radius: 12)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: previewedTyre)
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
}

#Preview {
    CarViewerView(model: CarEditorModel(), previewedTyre: .constant(nil))
        .frame(height: 360)
}
