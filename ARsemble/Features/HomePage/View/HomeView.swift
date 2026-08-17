//
//  HomeView.swift
//  
//
//  Created by Catherine Danielle on 12/08/26.
//


import SwiftUI

struct HomeView: View {
    private let lessons = [
        (num: 1, title: "Center of Gravity", image: "level1", done: 0, total: 10),
        (num: 2, title: "Friction",          image: "level1", done: 0, total: 10),
        (num: 3, title: "Momentum",          image: "level1", done: 0, total: 10)
    ]

    @State private var selection = 1

    private var padded: [(num: Int, title: String, image: String, done: Int, total: Int)] {
        guard let f = lessons.first, let l = lessons.last else { return [] }
        return [l] + lessons + [f]
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(padded.enumerated()), id: \.offset) { i, lesson in
                LessonCard(num: lesson.num, title: lesson.title,
                           image: lesson.image, done: lesson.done, total: lesson.total)
                    .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: selection) { _, new in
            if new == 0 { jump(to: lessons.count) }
            else if new == padded.count - 1 { jump(to: 1) }
        }
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

            HStack(spacing: 6) {
                Text("Level completed:")
                    .font(.system(size: 17, weight: .medium))
                Text("\(done)/\(total)")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.secondary)

            StartButton()
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView()
}

