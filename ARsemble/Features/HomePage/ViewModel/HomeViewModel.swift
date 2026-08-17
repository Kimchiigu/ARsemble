////
////  HomeViewModel.swift
////  ARsemble
////
////  Created by Catherine Danielle on 12/08/26.
////
//
//import SwiftUI
//
///// VIEWMODEL — owns the lessons and the logic the home screen needs.
///// `HomeView` observes this. It holds Models (`LessonItem`), it is not a Model itself.
//@Observable
//final class HomeViewModel {
//    private(set) var lessons: [LessonItem]
//
//    init(lessons: [LessonItem] = HomeViewModel.sample) {
//        self.lessons = lessons
//    }
//
//    /// Increment a lesson's completed-level count (call when a level is passed).
//    func markLevelPassed(lessonID: LessonItem.ID) {
//        guard let i = lessons.firstIndex(where: { $0.id == lessonID }),
//              lessons[i].isSuccessLevelCount < lessons[i].levelCount else { return }
//        lessons[i].isSuccessLevelCount += 1
//    }
//
//    func progressText(for lesson: LessonItem) -> String {
//        "\(lesson.isSuccessLevelCount)/\(lesson.levelCount)"
//    }
//
//    /// Three lessons -> the carousel loops 1 -> 2 -> 3 -> 1 ...
//    static let sample: [LessonItem] = [
//        LessonItem(lessonNumber: 1, title: "Center of Gravity", imageName: "IslandIllustration", levelCount: 10),
//        LessonItem(lessonNumber: 2, title: "Friction",          imageName: "IslandIllustration", levelCount: 10),
//        LessonItem(lessonNumber: 3, title: "Momentum",          imageName: "IslandIllustration", levelCount: 10)
//    ]
//}
