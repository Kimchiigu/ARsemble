//
//  CarViewerView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import RealityKit
import SwiftUI
import UIKit

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
        CarViewerScene(holder: holder, lighting: lighting)
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
                        applyTransform()
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
                        applyTransform()
                    }
                    .onEnded { _ in lastMagnification = 1.0 }
            )
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .task {
                if !Self.systemsRegistered {
                    CarAssemblySystem.registerSystem()
                    Self.systemsRegistered = true
                }

                buildLighting(into: lighting)

                await CarBuilder.prepareWheelAssets()
                applySpec()
                CarBuilder.invalidateBuildState(on: holder)
                applyTransform()
            }
            // `RealityView`'s `update:` closure used to re-apply the spec on
            // every SwiftUI pass. Observing the spec directly is both cheaper
            // and explicit about what actually drives a rebuild.
            .onChange(of: viewModel.carSpec) { _, _ in
                applySpec()
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


// MARK: - Non-AR RealityKit scene

/// The editor's 3D stage.
///
/// Deliberately an `ARView` with `cameraMode: .nonAR` and NOT SwiftUI's
/// `RealityView`. RealityKit builds its render graph once per process: a live
/// `RealityView` earlier in the session left the AR screen's `ARView` unable to
/// build its passthrough pass (`arKitPassthrough.rematerial`), so the camera
/// background stayed black while 3D content kept rendering normally. Using the
/// same view type on both screens removes that conflict.
private struct CarViewerScene: UIViewRepresentable {

    /// Distance of the viewer camera from the car, in metres. At
    /// `CarBuilder.displayScale` a default car is roughly 0.5 m long.
    /// Increase to pull back, decrease to fill more of the card.
    private static let cameraDistance: Float = 1.25

    /// Height of the camera above the car's centre — a slight top-down angle.
    private static let cameraHeight: Float = 0.22

    let holder: Entity
    let lighting: Entity

    func makeUIView(context: Context) -> ARView {

        let view = ARView(
            frame: CGRect(x: 0, y: 0, width: 512, height: 400),
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )

        // Transparent so the SwiftUI rounded-rect background shows through.
        view.environment.background = .color(.clear)
        view.backgroundColor = .clear
        view.isOpaque = false

        let root = AnchorEntity(world: .zero)
        root.addChild(holder)
        root.addChild(lighting)
        view.scene.addAnchor(root)

        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 40

        let position = SIMD3<Float>(0, Self.cameraHeight, Self.cameraDistance)
        camera.position = position
        camera.look(at: .zero, from: position, relativeTo: nil)

        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        view.scene.addAnchor(cameraAnchor)

        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // The scene is driven entirely by the entities passed in.
    }
}


#Preview {
    CarViewerView(viewModel: EditorViewModel())
        .frame(height: 360)
}
