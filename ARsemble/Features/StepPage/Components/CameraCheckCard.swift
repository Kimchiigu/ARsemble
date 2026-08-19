//
//  CameraCheckCard.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import AVFoundation
import SwiftUI

/// Owns the step-page capture session and serializes all access to it. The
/// editor/AR transition waits for `stop` to finish before presenting ARKit.
final class StepCameraSession: ObservableObject {

    let captureSession = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "step-camera-check")

    func start() {
        sessionQueue.async { [captureSession] in
            guard captureSession.inputs.isEmpty else {
                if !captureSession.isRunning {
                    captureSession.startRunning()
                }
                return
            }

            captureSession.beginConfiguration()
            captureSession.sessionPreset = .high

            if let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
               let input = try? AVCaptureDeviceInput(device: device),
               captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            captureSession.commitConfiguration()
            captureSession.startRunning()
        }
    }

    /// Calls completion on the main actor only after AVFoundation has released
    /// the camera, so ARKit never starts alongside this capture session.
    ///
    /// `stopRunning()` on its own is NOT enough: the session keeps its
    /// `AVCaptureDeviceInput`, which keeps the back camera bound to this
    /// process. StepView also stays alive underneath the pushed AR screen, so
    /// that input would outlive the page it belongs to. Removing the inputs
    /// hands the camera back for real before ARKit asks for it. `start()`
    /// re-adds the input, so returning to this page still works.
    func stop(completion: @escaping @MainActor () -> Void = {}) {
        sessionQueue.async { [captureSession] in
            if captureSession.isRunning {
                captureSession.stopRunning()
            }

            if !captureSession.inputs.isEmpty {
                captureSession.beginConfiguration()

                for input in captureSession.inputs {
                    captureSession.removeInput(input)
                }

                captureSession.commitConfiguration()
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

/// Live camera shown DIRECTLY inside the last step's image card, with the
/// step's ramp reference picture overlaid — so the player can hold the device
/// up to their real-world ramp and compare it against the example without
/// leaving the page. The small slider fades the reference in and out.
struct CameraCheckCard: View {

    /// Reference image drawn over the camera feed (e.g. "step5-2").
    var overlayImage: String

    @ObservedObject var camera: StepCameraSession

    @State private var overlayOpacity = 0.5
    @State private var cameraAllowed = false
    @State private var permissionChecked = false

    var body: some View {
        ZStack {
            Color.black

            if cameraAllowed {
                CameraPreview(session: camera.captureSession)

                // The ramp reference, sized to sit INSIDE the card (not
                // full-bleed) so the camera feed stays visible around it.
                Image(overlayImage)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .opacity(overlayOpacity)
                    .allowsHitTesting(false)
            } else if permissionChecked {
                permissionMessage
            }

            VStack {
                Spacer()

                if cameraAllowed {
                    opacitySlider
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task { await requestCameraAccess() }
        .onDisappear {
            camera.stop()
        }
    }

    private var opacitySlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera")
                .foregroundStyle(.white)

            Slider(value: $overlayOpacity, in: 0.1...0.9)

            Image(systemName: "photo")
                .foregroundStyle(.white)
        }
        .frame(maxWidth: 360)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .padding(.bottom, 16)
    }

    private var permissionMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.7))

            Text("Camera access is needed to check your ramp.")
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            if let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") {
                    UIApplication.shared.open(url)
                }
                .buttonBorderShape(.roundedRectangle)
                .padding(.top, 4)
            }
        }
        .padding(24)
    }

    private func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAllowed = true

        case .notDetermined:
            cameraAllowed = await AVCaptureDevice.requestAccess(for: .video)

        default:
            cameraAllowed = false
        }

        permissionChecked = true

        if cameraAllowed {
            camera.start()
        }
    }
}

// MARK: - Camera preview layer

private struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    final class PreviewView: UIView {

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            // The connection only exists once the session has an input and is
            // running, which happens AFTER this view is built. Without this the
            // rotation is applied to nothing and the feed keeps its default.
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sessionStarted),
                name: AVCaptureSession.didStartRunningNotification,
                object: nil
            )
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func sessionStarted() {
            DispatchQueue.main.async { [weak self] in
                self?.applyRotation()
            }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyRotation()
        }

        /// `layoutSubviews`, not `updateUIView`: the first `updateUIView` runs
        /// before the view has a window, so the interface orientation is
        /// unknown and the old code fell through to its `.portrait` default —
        /// which is exactly a 90° tilted feed on a landscape iPad.
        override func layoutSubviews() {
            super.layoutSubviews()
            applyRotation()
        }

        private func applyRotation() {

            guard let connection = previewLayer.connection else {
                return
            }

            let orientation = window?.windowScene?.interfaceOrientation
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .interfaceOrientation
                ?? .landscapeLeft

            // UIInterfaceOrientation and the capture rotation angle do NOT
            // line up name for name — the two landscape cases are mirrored.
            // Mapping `.landscapeLeft` straight onto `.landscapeLeft` is the
            // other half of this bug and flips the feed by 180°.
            let angle: CGFloat

            switch orientation {
            case .portrait:           angle = 90
            case .portraitUpsideDown: angle = 270
            case .landscapeLeft:      angle = 180
            case .landscapeRight:     angle = 0
            default:                  angle = 0
            }

            guard
                connection.isVideoRotationAngleSupported(angle),
                connection.videoRotationAngle != angle
            else {
                return
            }

            connection.videoRotationAngle = angle
        }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView(frame: .zero)
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.setNeedsLayout()
    }
}

#Preview(traits: .landscapeLeft) {
    CameraCheckCard(
        overlayImage: "step5-2",
        camera: StepCameraSession()
    )
        .frame(width: 723, height: 519)
        .padding()
}
