//
//  HomeView.swift
//
//
//  Created by Catherine Danielle on 12/08/26.
//


import SwiftUI

struct HomeView: View {
    /// Called with the lesson number when "Start Learning" is tapped.
    var onStartLesson: (Int) -> Void = { _ in }

    @State private var viewModel = HomeViewModel()
    @State private var selection = 1
    @Environment(LevelProgressStore.self) private var progress

    private var padded: [HomeModel] {
        guard let f = viewModel.lessons.first, let l = viewModel.lessons.last else { return [] }
        return [l] + viewModel.lessons + [f]
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(padded.enumerated()), id: \.offset) { i, lesson in
                LessonCard(
                    num: lesson.lessonNumber,
                    title: lesson.title,
                    image: lesson.imageName,
                    done: progress.completedCount(lesson: lesson.lessonNumber),
                    total: lesson.levelCount,
                    locked: !hasContent(lesson),
                    onStart: { onStartLesson(lesson.lessonNumber) }
                )
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: selection) { _, new in
            if new == 0 { jump(to: viewModel.lessons.count) }
            else if new == padded.count - 1 { jump(to: 1) }
        }
    }

    /// Only lesson 1 has content (novel, concept, steps) so far.
    private func hasContent(_ lesson: HomeModel) -> Bool {
        lesson.lessonNumber == 1
    }

    private func jump(to index: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            var tx = Transaction(); tx.disablesAnimations = true
            withTransaction(tx) { selection = index }
        }
    }
}

struct LessonCard: View {
    let num: Int
    let title: String
    let image: String
    let done: Int
    let total: Int
    var locked: Bool = false
    var onStart: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 585, height: 424)

            Text("Lesson \(num)")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(size: 34, weight: .bold))

            if locked {
                HStack(spacing: 6) {
                    Image("lock")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("Locked")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.secondary)

                StartButton()
                    .padding(.top, 8)
                    .opacity(0.35)
                    .disabled(true)
            } else {
                HStack(spacing: 6) {
                    Text("Level completed:")
                        .font(.system(size: 17, weight: .medium))
                    Text("\(done)/\(total)")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.secondary)

                StartButton(action: onStart)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView()
        .environment(LevelProgressStore())
}

