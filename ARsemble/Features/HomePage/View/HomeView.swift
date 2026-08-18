//
//  HomeView.swift
//
//
//  Created by Catherine Danielle on 12/08/26.
//

import SwiftUI

struct HomeView: View {
    var onStartLesson: (Int) -> Void = { _ in }

    @State private var viewModel = HomeViewModel()
    @State private var scrollID: Int?
    @Environment(LevelProgressStore.self) private var progress

    private var padded: [HomeModel] {
        guard let f = viewModel.lessons.first,
              let l = viewModel.lessons.last else {
            return []
        }
        return [l] + viewModel.lessons + [f]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("G1"),
                    Color("G2")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let spacing: CGFloat = 32
                let sideInset = geo.size.width * 0.1
                let cardWidth = geo.size.width - (sideInset * 2) - spacing

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(
                            Array(padded.enumerated()),
                            id: \.offset
                        ) { i, lesson in
                            LessonCard(
                                num: lesson.lessonNumber,
                                title: lesson.title,
                                image: lesson.imageName,
                                done: progress.completedCount(
                                    lesson: lesson.lessonNumber
                                ),
                                total: lesson.levelCount,
                                locked: !hasContent(lesson),
                                onStart: {
                                    onStartLesson(lesson.lessonNumber)
                                }
                            )
                            .frame(width: cardWidth)
                            .id(i)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, sideInset, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollID)
                .onAppear { scrollID = 1 }
                .onChange(of: scrollID) { _, new in
                    guard let new else { return }
                    if new == 0 {
                        jump(to: viewModel.lessons.count)
                    } else if new == padded.count - 1 {
                        jump(to: 1)
                    }
                }
            }
        }
    }

    private func hasContent(_ lesson: HomeModel) -> Bool {
        lesson.lessonNumber == 1
    }

    private func jump(to index: Int) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35
        ) {
            var tx = Transaction()
            tx.disablesAnimations = true

            withTransaction(tx) {
                scrollID = index
            }
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

    private var attributedLessonTitle: AttributedString {
        let label = "Lesson \(num): "
        var attrStr = AttributedString(label + title)
        if let labelRange = attrStr.range(of: label) {
            attrStr[labelRange].font = .system(size: 28, weight: .medium)
            attrStr[labelRange].foregroundColor = .primary
        }
        if let titleRange = attrStr.range(of: title) {
            attrStr[titleRange].font = .system(size: 28, weight: .bold)
            attrStr[titleRange].foregroundColor = .primary
        }
        return attrStr
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 610,
                        height: 447
                    )
                    .saturation(locked ? 0 : 1)
                    .brightness(locked ? -0.15 : 0)

                if locked {
                    VStack(spacing: 10) {
                        Image("lock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)

                        Text("Finish the previous lesson to unlock")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .shadow(radius: 4)
                    }
                }
            }

            Text(attributedLessonTitle)

            HStack(spacing: 6) {
                Text("Completed:")
                    .font(
                        .system(
                            size: 17,
                            weight: .medium
                        )
                    )

                Text("\(done)/\(total)")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
            }
            .foregroundStyle(.secondary)

            StartButton(action: locked ? {} : onStart)
                .padding(.top, 8)
                .opacity(locked ? 0.4 : 1)
                .disabled(locked)

            Spacer()
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


#Preview(traits: .landscapeLeft) {
    HomeView()
        .environment(LevelProgressStore())
}
