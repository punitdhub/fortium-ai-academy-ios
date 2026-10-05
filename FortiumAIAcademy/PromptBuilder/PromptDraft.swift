import SwiftUI

/// The learner's answers in the Prompt Builder, and the prompt they produce.
struct PromptDraft: Equatable {
    var goal: PromptGoal
    var task = ""
    var context = ""
    var audience = ""
    var tones: [String] = []
    var format = ""
    var lengthIndex = 1
    var extras: Set<String> = []

    init(goal: PromptGoal) {
        self.goal = goal
        format = goal.formats.first ?? ""
        extras = ["Ask me questions first if anything is unclear"]
    }

    var allExtras: [String] { goal.extras + PromptCatalog.universalExtras }

    /// Builds a clearly-labeled, beginner-readable prompt that follows the
    /// Role → Task → Context → Audience → Tone → Format recipe taught in the course.
    var assembled: String {
        var parts: [String] = [goal.role]

        let trimmedTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        parts.append("Here's what I need: " + (trimmedTask.isEmpty ? "[describe your task]" : trimmedTask.endingWithPeriod))

        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedContext.isEmpty {
            parts.append("Some background: " + trimmedContext.endingWithPeriod)
        }

        if !audience.isEmpty {
            parts.append("Who it's for: " + audience.endingWithPeriod)
        }

        if !tones.isEmpty {
            let toneList = ListFormatter.localizedString(byJoining: tones.map { $0.lowercased() })
            parts.append("Tone: Please make it \(toneList).")
        }

        var formatLine = ""
        if !format.isEmpty { formatLine = "Format: \(format.endingWithPeriod) " }
        formatLine += PromptCatalog.lengths[lengthIndex].phrase
        parts.append(formatLine)

        let orderedExtras = allExtras.filter { extras.contains($0) }
        if !orderedExtras.isEmpty {
            parts.append("A few more things:\n" + orderedExtras.map { "- \($0)" }.joined(separator: "\n"))
        }

        return parts.joined(separator: "\n\n")
    }

    // MARK: Prompt strength

    struct Check: Identifiable {
        let id: String
        let label: String
        let tip: String
        let passed: Bool
    }

    var checks: [Check] {
        let words = task.split(whereSeparator: \.isWhitespace).count
        return [
            Check(id: "task", label: "Clear task", tip: "Describe what you want in at least a few words.", passed: words >= 4),
            Check(id: "context", label: "Background", tip: "Add context: the situation, details, or constraints.", passed: context.split(whereSeparator: \.isWhitespace).count >= 5),
            Check(id: "audience", label: "Audience", tip: "Say who it's for — Claude adjusts the wording.", passed: !audience.isEmpty),
            Check(id: "tone", label: "Tone", tip: "Pick a tone so it sounds the way you want.", passed: !tones.isEmpty),
            Check(id: "format", label: "Format", tip: "Choose a format so you get it in a useful shape.", passed: !format.isEmpty),
        ]
    }

    var strength: Double {
        let list = checks
        return Double(list.filter(\.passed).count) / Double(list.count)
    }

    var strengthLabel: String {
        switch strength {
        case ..<0.4: "Getting started"
        case ..<0.8: "Good"
        case ..<1: "Great"
        default: "Excellent"
        }
    }
}

private extension String {
    var endingWithPeriod: String {
        guard let last = last else { return self }
        return ".!?:".contains(last) ? self : self + "."
    }
}

// MARK: - Saved prompts

struct SavedPrompt: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var goalID: String
    var text: String
    var createdAt = Date()
}

@Observable
final class PromptLibrary {
    private(set) var prompts: [SavedPrompt] = []
    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("saved-prompts.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([SavedPrompt].self, from: data) {
            prompts = decoded
        }
    }

    func add(_ prompt: SavedPrompt) {
        prompts.insert(prompt, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        prompts.remove(atOffsets: offsets)
        save()
    }

    func delete(_ prompt: SavedPrompt) {
        prompts.removeAll { $0.id == prompt.id }
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try JSONEncoder().encode(prompts).write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save prompts: \(error)")
        }
    }
}
