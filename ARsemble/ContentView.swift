//
//  ContentView.swift
//  ARsemble
//
//  Created by Reynard Amadeus on 10/08/26.
//

import SwiftUI

struct ContentView: View {

    /// DEBUG A/B SWITCH — set to `true` to open AR straight from Home.
    ///
    /// The point is to reach AR WITHOUT the editor's `RealityView` ever having
    /// been created in this process. RealityKit builds its render graph once
    /// per process; if a non-AR `RealityView` initialises it first, the AR
    /// passthrough pass (`arKitPassthrough.rematerial`) can fail to build and
    /// the camera background stays black while 3D content still renders.
    ///
    /// - camera VISIBLE here, black after visiting the editor
    ///   → the editor's RealityView is the cause.
    /// - camera BLACK here too
    ///   → the cause is elsewhere in app startup, not the editor.
    ///
    /// Set back to `false` once the answer is known.
    private let debugSkipToAR = false

    @State private var router = Router()
    @State private var progress = LevelProgressStore()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView { lesson in
                if debugSkipToAR {
                    router.presentAR(
                        lesson: lesson,
                        level: 1,
                        spec: EntityFactory.placeholderCarSpec()
                    )
                } else {
                    router.push(.level(lesson: lesson))
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
                    .toolbarVisibility(.hidden, for: .navigationBar)
            }
        }
        .environment(router)
        .environment(progress)
        .fullScreenCover(item: $router.arPresentation) { presentation in
            SurfaceScannerView(carSpec: presentation.spec) {
                progress.complete(
                    level: presentation.level,
                    lesson: presentation.lesson
                )

                router.returnToLevelMap(lesson: presentation.lesson)
            }
            .environment(router)
            .environment(progress)
        }
        .onAppear {
            SoundManager.shared.playBackgroundMusic(named: "music-bg")
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .level(let lesson):
            LevelView(lesson: lesson) { level in
                router.push(.novel(lesson: lesson, level: level))
            }

        case .novel(let lesson, let level):
            NovelView {
                router.push(.concept(lesson: lesson, level: level))
            }

        case .concept(let lesson, let level):
            ConceptView {
                router.push(.step(lesson: lesson, level: level))
            }

        case .step(let lesson, let level):
            StepView {
                router.push(.editor(lesson: lesson, level: level))
            }

        case .editor(let lesson, let level):
            EditorView { spec in
                router.presentAR(
                    lesson: lesson,
                    level: level,
                    spec: spec
                )
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
