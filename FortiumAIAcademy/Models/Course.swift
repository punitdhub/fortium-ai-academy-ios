import SwiftUI

// The course is defined in Content/course.json so lessons can be updated
// without touching code (and, later, downloaded from a server).

struct Course: Codable {
    let version: Int
    let title: String
    let sections: [CourseSection]
}

struct CourseSection: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: String
    let isFree: Bool
    let lessons: [Lesson]

    var tint: Color { Color(hex: color) }
    var totalMinutes: Int { lessons.reduce(0) { $0 + $1.minutes } }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let minutes: Int
    let cards: [LessonCard]
    let quiz: [QuizQuestion]

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct LessonCard: Codable, Hashable {
    enum Kind: String, Codable {
        case text, tip, steps, example, compare, tryIt, warning
    }

    let kind: Kind
    let title: String
    var body: String?
    var items: [String]?
    var prompt: String?
    var bad: String?
    var good: String?
}

struct QuizQuestion: Codable, Hashable {
    let question: String
    let options: [String]
    let answer: Int
    let explanation: String
}

@Observable
final class CourseStore {
    let course: Course

    init(bundle: Bundle = .main) {
        guard
            let url = bundle.url(forResource: "course", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let course = try? JSONDecoder().decode(Course.self, from: data)
        else {
            assertionFailure("course.json is missing or invalid — run scripts/validate_content.py")
            self.course = Course(version: 0, title: "", sections: [])
            return
        }
        self.course = course
    }

    var sections: [CourseSection] { course.sections }
    var allLessons: [Lesson] { course.sections.flatMap(\.lessons) }

    func section(containing lessonID: String) -> CourseSection? {
        course.sections.first { $0.lessons.contains { $0.id == lessonID } }
    }

    func lesson(id: String) -> Lesson? {
        allLessons.first { $0.id == id }
    }

    /// The lesson that follows `lessonID` across sections, if any.
    func nextLesson(after lessonID: String) -> (section: CourseSection, lesson: Lesson)? {
        let pairs = course.sections.flatMap { section in section.lessons.map { (section, $0) } }
        guard let index = pairs.firstIndex(where: { $0.1.id == lessonID }), index + 1 < pairs.count else {
            return nil
        }
        return (pairs[index + 1].0, pairs[index + 1].1)
    }

    /// First lesson the learner hasn't finished yet.
    func firstIncomplete(completed: Set<String>) -> (section: CourseSection, lesson: Lesson)? {
        for section in course.sections {
            if let lesson = section.lessons.first(where: { !completed.contains($0.id) }) {
                return (section, lesson)
            }
        }
        return nil
    }
}
