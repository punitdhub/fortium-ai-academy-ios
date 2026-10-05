import Foundation

struct ProgressData: Codable {
    var completedLessons: Set<String> = []
    var bestScores: [String: Int] = [:]
    var xp: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDay: Date?
    var badges: Set<String> = []
    var perfectQuizzes: Int = 0
    var promptsBuilt: Int = 0
    var lastLessonID: String?
    var graduationDate: Date?
}

/// What happened when a learner finished a lesson — drives the celebration screen.
struct LessonResult: Equatable {
    let score: Int
    let total: Int
    let xpEarned: Int
    let isFirstCompletion: Bool
    let newBadges: [Badge]
    let completedSection: CourseSection?
    let completedCourse: Bool
    let streak: Int

    var isPerfect: Bool { score == total && total > 0 }
}

enum XP {
    static let lessonComplete = 50
    static let perCorrectAnswer = 10
    static let perfectBonus = 25
    static let sectionBonus = 100
    static let replayPerCorrect = 5
    static let promptBuilt = 15
}

@Observable
final class ProgressStore {
    private(set) var data: ProgressData
    private let fileURL: URL

    init(fileName: String = "progress.json") {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent(fileName)
        if let saved = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(ProgressData.self, from: saved) {
            data = decoded
        } else {
            data = ProgressData()
        }
        #if DEBUG
        if Demo.seedProgress { data = Demo.sampleProgress() }
        #endif
    }

    // MARK: Queries

    func isCompleted(_ lesson: Lesson) -> Bool {
        data.completedLessons.contains(lesson.id)
    }

    func completedCount(in section: CourseSection) -> Int {
        section.lessons.filter { data.completedLessons.contains($0.id) }.count
    }

    func progress(for section: CourseSection) -> Double {
        guard !section.lessons.isEmpty else { return 0 }
        return Double(completedCount(in: section)) / Double(section.lessons.count)
    }

    func overallProgress(_ course: Course) -> Double {
        let total = course.sections.reduce(0) { $0 + $1.lessons.count }
        guard total > 0 else { return 0 }
        return Double(completedLessonCount(course)) / Double(total)
    }

    func completedLessonCount(_ course: Course) -> Int {
        course.sections.flatMap(\.lessons).filter { data.completedLessons.contains($0.id) }.count
    }

    func hasBadge(_ badge: Badge) -> Bool {
        data.badges.contains(badge.rawValue)
    }

    /// The streak shown to the learner: it drops to 0 if they skipped a day.
    var displayStreak: Int {
        guard let last = data.lastActiveDay else { return 0 }
        let calendar = Calendar.current
        if calendar.isDateInToday(last) || calendar.isDateInYesterday(last) {
            return data.currentStreak
        }
        return 0
    }

    // MARK: Updates

    /// Opening the app doesn't count toward the streak; finishing a lesson
    /// or building a prompt does. This just keeps a stale streak honest.
    func registerVisit() {
        if displayStreak == 0, data.currentStreak != 0 {
            data.currentStreak = 0
            save()
        }
    }

    func completeLesson(_ lesson: Lesson, in section: CourseSection, course: Course,
                        score: Int, total: Int) -> LessonResult {
        let firstTime = !data.completedLessons.contains(lesson.id)
        let sectionWasComplete = progress(for: section) >= 1
        let wasHalfway = overallProgress(course) >= 0.5
        let previousBest = data.bestScores[lesson.id] ?? 0
        let perfect = score == total && total > 0

        var earned = 0
        if firstTime {
            earned += XP.lessonComplete + score * XP.perCorrectAnswer
            if perfect { earned += XP.perfectBonus }
        } else {
            earned += score * XP.replayPerCorrect
            if perfect && previousBest < total { earned += XP.perfectBonus }
        }

        data.completedLessons.insert(lesson.id)
        data.bestScores[lesson.id] = max(previousBest, score)
        data.lastLessonID = lesson.id
        if perfect && previousBest < total { data.perfectQuizzes += 1 }

        var finishedSection: CourseSection?
        if !sectionWasComplete && progress(for: section) >= 1 {
            finishedSection = section
            earned += XP.sectionBonus
        }
        let finishedCourse = overallProgress(course) >= 1 && data.graduationDate == nil
        if finishedCourse { data.graduationDate = Date() }

        data.xp += earned
        bumpStreak()

        var newBadges: [Badge] = []
        func award(_ badge: Badge, if condition: Bool) {
            if condition && !data.badges.contains(badge.rawValue) {
                data.badges.insert(badge.rawValue)
                newBadges.append(badge)
            }
        }
        award(.firstStep, if: true)
        award(.perfectScore, if: perfect)
        award(.quizWhiz, if: data.perfectQuizzes >= 5)
        award(.firstSection, if: finishedSection != nil)
        award(.halfway, if: !wasHalfway && overallProgress(course) >= 0.5)
        award(.graduate, if: finishedCourse)
        award(.streak3, if: data.currentStreak >= 3)
        award(.streak7, if: data.currentStreak >= 7)

        save()
        return LessonResult(score: score, total: total, xpEarned: earned, isFirstCompletion: firstTime,
                            newBadges: newBadges, completedSection: finishedSection,
                            completedCourse: finishedCourse, streak: data.currentStreak)
    }

    /// Called when a learner copies/opens/saves a prompt from the builder.
    @discardableResult
    func recordPromptBuilt(savedCount: Int) -> [Badge] {
        data.promptsBuilt += 1
        if data.promptsBuilt == 1 { data.xp += XP.promptBuilt }
        bumpStreak()
        var newBadges: [Badge] = []
        if !data.badges.contains(Badge.promptCrafter.rawValue) {
            data.badges.insert(Badge.promptCrafter.rawValue)
            newBadges.append(.promptCrafter)
        }
        if savedCount >= 5, !data.badges.contains(Badge.promptCollector.rawValue) {
            data.badges.insert(Badge.promptCollector.rawValue)
            newBadges.append(.promptCollector)
        }
        for badge in [Badge.streak3, .streak7] where !data.badges.contains(badge.rawValue) {
            let needed = badge == .streak3 ? 3 : 7
            if data.currentStreak >= needed {
                data.badges.insert(badge.rawValue)
                newBadges.append(badge)
            }
        }
        save()
        return newBadges
    }

    func reset() {
        data = ProgressData()
        save()
    }

    // MARK: Private

    private func bumpStreak() {
        let calendar = Calendar.current
        let now = Date()
        if let last = data.lastActiveDay {
            if calendar.isDateInToday(last) {
                // Already counted today.
            } else if calendar.isDateInYesterday(last) {
                data.currentStreak += 1
            } else {
                data.currentStreak = 1
            }
        } else {
            data.currentStreak = 1
        }
        data.lastActiveDay = now
        data.longestStreak = max(data.longestStreak, data.currentStreak)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(data).write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}
