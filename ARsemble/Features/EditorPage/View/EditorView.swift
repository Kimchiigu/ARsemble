//
//  EditorView.swift
//  ARsemble
//
//  Created by Christopher Hardy Gunawan on 12/08/26.
//

import SwiftUI

struct EditorView: View {
    @State private var viewModel = EditorViewModel()
    @State private var showResetAlert = false
    @State private var phase: Phase = .editing
    @State private var curtain = false

    private enum Phase { case editing, presenting, result }

    var body: some View {
        ZStack {
            editorContent

            if phase == .result {
                ResultView(onBack: backToEditor)
                    .transition(.opacity)
            }

            Color(.systemBackground)
                .ignoresSafeArea()
                .opacity(curtain ? 1 : 0)
                .allowsHitTesting(false)
        }
        .alert("Are you sure you want to reset to default?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                viewModel.reset()
            }
            Button("Continue Edit", role: .cancel) {}
        } message: {
            Text("All changes to your car will be lost")
        }
    }

    private var editorContent: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CarViewerView(viewModel: viewModel, isPresenting: phase != .editing)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if phase == .editing {
                        EditorConfigView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)

                if phase == .editing {
                    bottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(phase == .editing ? 16 : 0)
        }
    }

    private var bottomBar: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 64, height: 64)

                Image("armadillo-editor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                    )

                BubbleTail()
                    .fill(Color.blue)
                    .frame(width: 20, height: 24)
                    .offset(x: -18)

                Text("Build a car that has a low center of gravity.")
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .font(.title3)
                    .bold()
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                showResetAlert = true
            } label: {
                Text("Reset to Default")
                    .foregroundStyle(Color.primary)
            }
            .buttonBorderShape(.roundedRectangle)
            .padding()
            .frame(width: 200)
            .glassEffect()

            Button {
                startCinematic()
            } label: {
                Text("Ready")
                    .foregroundStyle(Color.white)
            }
            .buttonBorderShape(.roundedRectangle)
            .padding()
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.orange)
            )
            .glassEffect()
        }
    }

    private func startCinematic() {
        withAnimation(.easeInOut(duration: 0.55)) {
            phase = .presenting
        }

        Task {
            try? await Task.sleep(for: .seconds(0.7))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.45)) { curtain = true }
            try? await Task.sleep(for: .seconds(0.5))
            if Task.isCancelled { return }
            phase = .result
            try? await Task.sleep(for: .seconds(0.05))
            withAnimation(.easeInOut(duration: 0.45)) { curtain = false }
        }
    }

    private func backToEditor() {
        withAnimation(.easeInOut(duration: 0.45)) { curtain = true }

        Task {
            try? await Task.sleep(for: .seconds(0.5))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.55)) { phase = .editing }
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.easeInOut(duration: 0.45)) { curtain = false }
        }
    }
}

#Preview {
    EditorView()
}
