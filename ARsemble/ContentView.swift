//
//  ContentView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 10/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var router = Router()
    @State private var progress = LevelProgressStore()

    var body: some View {
        SurfaceScannerView()
            .onAppear {
                SoundManager.shared.playBackgroundMusic(named: "music-bg")
            }
        NavigationStack(path: $router.path) {
            HomeView { lesson in
                router.push(.level(lesson: lesson))
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
                    .toolbarVisibility(.hidden, for: .navigationBar)
            }
        }
        .environment(router)
        .environment(progress)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .level(let lesson):
            LevelView(lesson: lesson) { level in
                router.push(.novel(lesson: lesson, level: level))
            }

        case .novel(let lesson, let level):
            NovelView(onContinue: {
                router.push(.concept(lesson: lesson, level: level))
            })

        case .concept(let lesson, let level):
            ConceptView(onFinish: {
                router.push(.step(lesson: lesson, level: level))
            })

        case .step(let lesson, let level):
            StepView(onBuild: {
                router.push(.editor(lesson: lesson, level: level))
            })

        case .editor(let lesson, let level):
            EditorView(onReady: { spec in
                router.push(.ar(lesson: lesson, level: level, spec: spec))
            })

        case .ar(let lesson, let level, let spec):
            SurfaceScannerView(carSpec: spec) {
                progress.complete(level: level, lesson: lesson)
                router.returnToLevelMap(lesson: lesson)
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
