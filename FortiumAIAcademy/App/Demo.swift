#if DEBUG
import Foundation

/// Debug-only hooks used by the screenshot workflow (.github/workflows/screenshots.yml).
/// Launch with e.g. `-demoScreen lesson -demoSeed YES`. Compiled out of App Store builds.
enum Demo {
    static var screen: String? { UserDefaults.standard.string(forKey: "demoScreen") }
    static var seedProgress: Bool { UserDefaults.standard.bool(forKey: "demoSeed") }

    static func `is`(_ name: String) -> Bool { screen == name }

    /// Sample progress so Home and Progress screenshots look lived-in.
    static func sampleProgress() -> ProgressData {
        var data = ProgressData()
        data.completedLessons = ["what-is-claude", "getting-claude", "first-chat",
                                 "prompt-recipe", "follow-ups", "uploading-files"]
        data.bestScores = ["what-is-claude": 3, "getting-claude": 3, "first-chat": 2,
                           "prompt-recipe": 3, "follow-ups": 3, "uploading-files": 2]
        data.xp = 640
        data.currentStreak = 4
        data.longestStreak = 6
        data.lastActiveDay = Date()
        data.badges = Set([Badge.firstStep, .perfectScore, .promptCrafter, .streak3, .firstSection].map(\.rawValue))
        data.perfectQuizzes = 4
        data.promptsBuilt = 3
        return data
    }

    static func sampleResult(section: CourseSection) -> LessonResult {
        LessonResult(score: 3, total: 3, xpEarned: 205, isFirstCompletion: true,
                     newBadges: [.perfectScore, .firstSection], completedSection: section,
                     completedCourse: false, streak: 4)
    }

    static func fill(_ draft: inout PromptDraft) {
        draft.task = "Ask my manager for next Friday off"
        draft.context = "I finished my project early and a teammate has agreed to cover my tasks."
        draft.audience = "My manager"
        draft.tones = ["Friendly", "Professional"]
        draft.lengthIndex = 0
    }
}
#endif
