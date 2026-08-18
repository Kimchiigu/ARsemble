//
//  CameraCheckCard.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 18/08/26.
//

import AVFoundation
import SwiftUI

/// Live camera shown DIRECTLY inside the last step's image card, with the
/// step's ramp reference picture overlaid — so the player can hold the device
/// up to their real-world ramp and compare it against the example without
/// leaving the page. The small slider fades the reference in and out.
struct CameraCheckCard: View {

    /// Reference image drawn over the camera feed (e.g. "step5-2").
    var overlayImage: String

    @State private var session = AVCaptureSession()
    @State private var overlayOpacity = 0.5
    @State private var cameraAllowed = false
    @State private var permissionChecked = false

    private let sessionQueue = DispatchQueue(label: "step-camera-check")

    var body: some View {
        ZStack {
            Color.black

            if cameraAllowed {
                CameraPreview(session: session)

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
            sessionQueue.async { [session] in
                if session.isRunning {
                    session.stopRunning()
                }
            }
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
            configureSession()
        }
    }

    private func configureSession() {
        sessionQueue.async { [session] in
            guard session.inputs.isEmpty else { return }

            session.beginConfiguration()
            session.sessionPreset = .high

            if let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }

            session.commitConfiguration()
            session.startRunning()
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
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Keep the feed upright for the current interface orientation.
        let orientation: AVCaptureVideoOrientation
        switch uiView.window?.windowScene?.interfaceOrientation {
        case .portraitUpsideDown: orientation = .portraitUpsideDown
        case .landscapeLeft: orientation = .landscapeLeft
        case .landscapeRight: orientation = .landscapeRight
        default: orientation = .portrait
        }

        if let connection = uiView.previewLayer.connection,
           connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    }
}

#Preview(traits: .landscapeLeft) {
    CameraCheckCard(overlayImage: "step5-2")
        .frame(width: 723, height: 519)
        .padding()
}
