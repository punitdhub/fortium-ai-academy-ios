import SwiftUI

/// One question at a time, instant feedback with a friendly explanation.
struct QuizView: View {
    let questions: [QuizQuestion]
    let tint: Color
    let onFinish: (Int) -> Void

    @State var index = 0
    @State var selected: Int?
    @State var correctCount = 0

    private var question: QuizQuestion { questions[index] }
    private var answered: Bool { selected != nil }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label("QUICK QUIZ", systemImage: "checklist")
                            .font(.rounded(.caption, weight: .heavy))
                            .foregroundStyle(tint)
                        Spacer()
                        Text("Question \(index + 1) of \(questions.count)")
                            .font(.rounded(.caption, weight: .bold))
                            .foregroundStyle(.secondary)
                    }

                    Text(question.question)
                        .font(.rounded(.title2, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 12) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                            Button {
                                choose(optionIndex)
                            } label: {
                                OptionRow(text: option, state: state(for: optionIndex), tint: tint)
                            }
                            .buttonStyle(.plain)
                            .disabled(answered)
                        }
                    }

                    if let selected {
                        feedback(correct: selected == question.answer)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            Button(index + 1 < questions.count ? "Next question" : "See my results") {
                advance()
            }
            .buttonStyle(PrimaryButtonStyle(tint: tint))
            .disabled(!answered)
            .padding()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
    }

    private func state(for optionIndex: Int) -> OptionRow.Status {
        guard let selected else { return .idle }
        if optionIndex == question.answer { return .correct }
        if optionIndex == selected { return .wrong }
        return .dimmed
    }

    private func choose(_ optionIndex: Int) {
        guard selected == nil else { return }
        selected = optionIndex
        if optionIndex == question.answer {
            correctCount += 1
            Haptics.success()
        } else {
            Haptics.error()
        }
    }

    private func advance() {
        if index + 1 < questions.count {
            withAnimation {
                index += 1
                selected = nil
            }
        } else {
            onFinish(correctCount)
        }
    }

    private func feedback(correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(correct ? encouragement : "Not quite — here's why",
                  systemImage: correct ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(correct ? Theme.success : Theme.warning)
            Text(question.explanation.markdown)
                .font(.rounded(.body))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correct ? Theme.successSoft : Theme.goldSoft,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var encouragement: String {
        ["Correct! Nice work", "That's right!", "Exactly!", "You got it!"][index % 4]
    }
}

struct OptionRow: View {
    enum Status { case idle, correct, wrong, dimmed }

    let text: String
    let state: Status
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            switch state {
            case .correct:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success).font(.title3)
            case .wrong:
                Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.danger).font(.title3)
            default:
                EmptyView()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(fillColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor, lineWidth: state == .idle ? 1 : 2)
        )
        .opacity(state == .dimmed ? 0.55 : 1)
        .accessibilityValue(state == .correct ? "Correct answer" : state == .wrong ? "Your answer, incorrect" : "")
    }

    private var fillColor: Color {
        switch state {
        case .correct: Theme.successSoft
        case .wrong: Theme.dangerSoft
        default: Theme.surface
        }
    }

    private var borderColor: Color {
        switch state {
        case .correct: Theme.success
        case .wrong: Theme.danger
        default: Theme.stroke
        }
    }
}
