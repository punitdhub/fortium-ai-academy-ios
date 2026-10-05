import SwiftUI

enum Badge: String, CaseIterable, Codable, Identifiable {
    case firstStep
    case perfectScore
    case quizWhiz
    case promptCrafter
    case promptCollector
    case streak3
    case streak7
    case firstSection
    case halfway
    case graduate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStep: "First Step"
        case .perfectScore: "Perfect Score"
        case .quizWhiz: "Quiz Whiz"
        case .promptCrafter: "Prompt Crafter"
        case .promptCollector: "Prompt Collector"
        case .streak3: "On a Roll"
        case .streak7: "Week Warrior"
        case .firstSection: "Section Star"
        case .halfway: "Halfway Hero"
        case .graduate: "Academy Graduate"
        }
    }

    var detail: String {
        switch self {
        case .firstStep: "Finish your first lesson"
        case .perfectScore: "Get every quiz question right"
        case .quizWhiz: "Get 5 perfect quiz scores"
        case .promptCrafter: "Build your first prompt"
        case .promptCollector: "Save 5 prompts to your library"
        case .streak3: "Learn 3 days in a row"
        case .streak7: "Learn 7 days in a row"
        case .firstSection: "Complete a whole section"
        case .halfway: "Complete half of the course"
        case .graduate: "Complete the entire course"
        }
    }

    var icon: String {
        switch self {
        case .firstStep: "figure.walk"
        case .perfectScore: "star.fill"
        case .quizWhiz: "brain.head.profile"
        case .promptCrafter: "wand.and.stars"
        case .promptCollector: "books.vertical.fill"
        case .streak3: "flame.fill"
        case .streak7: "flame.circle.fill"
        case .firstSection: "rosette"
        case .halfway: "flag.checkered"
        case .graduate: "graduationcap.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstStep, .firstSection: Color(hex: "#4A6C8C")
        case .perfectScore, .quizWhiz: Color(hex: "#C9962E")
        case .promptCrafter, .promptCollector: Color(hex: "#8978AF")
        case .streak3, .streak7: Color(hex: "#D9643A")
        case .halfway: Color(hex: "#2E7D52")
        case .graduate: Color(hex: "#A87F40")
        }
    }
}
