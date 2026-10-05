import SwiftUI

/// Full-screen lesson experience: swipeable cards → quiz → celebration.
struct LessonFlowView: View {
    enum Phase: Equatable {
        case learn
        case quiz
        case retry(score: Int, total: Int)
        case celebrate(LessonResult)
    }

    @State var section: CourseSection
    @State var lesson: Lesson

    @Environment(\.dismiss) var dismiss
    @Environment(CourseStore.self) var courseStore
    @Environment(ProgressStore.self) var progress
    @Environment(SubscriptionStore.self) var subscriptions

    @State var phase: Phase = .learn
    @State var page = 0
    @State var quizAttempt = 0

    var body: some View {
        VStack(spacing: 0) {
            topBar
            switch phase {
            case .learn:
                learnPhase
            case .quiz:
                QuizView(questions: lesson.quiz, tint: section.tint) { score in
                    finishQuiz(score: score)
                }
                .id(quizAttempt)
            case let .retry(score, total):
                RetryView(score: score, total: total, tint: section.tint,
                          onReview: { page = 0; phase = .learn },
                          onRetry: { quizAttempt += 1; phase = .quiz })
            case let .celebrate(result):
                CelebrationView(result: result, section: section, lesson: lesson,
                                nextLesson: nextAccessibleLesson,
                                onNext: goToNextLesson,
                                onDone: { dismiss() })
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: phase)
        #if DEBUG
        .onAppear {
            if Demo.is("quiz") { phase = .quiz }
            if Demo.is("celebration") { phase = .celebrate(Demo.sampleResult(section: section)) }
        }
        #endif
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close lesson")

            ProgressBar(progress: barProgress, tint: section.tint, height: 10)

            Text(phaseLabel)
                .font(.rounded(.caption, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(minWidth: 44)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var barProgress: Double {
        let steps = Double(lesson.cards.count + 1)
        switch phase {
        case .learn: return Double(page + 1) / steps
        case .quiz, .retry: return Double(lesson.cards.count) / steps
        case .celebrate: return 1
        }
    }

    private var phaseLabel: String {
        switch phase {
        case .learn: return "\(page + 1)/\(lesson.cards.count)"
        case .quiz, .retry: return "Quiz"
        case .celebrate: return "Done"
        }
    }

    // MARK: Learn

    private var learnPhase: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(lesson.cards.enumerated()), id: \.offset) { index, card in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if index == 0 {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(section.title.uppercased())
                                        .font(.rounded(.caption, weight: .heavy))
                                        .foregroundStyle(section.tint)
                                    Text(lesson.title)
                                        .font(.rounded(.largeTitle, weight: .bold))
                                }
                                .padding(.bottom, 4)
                            }
                            LessonCardView(card: card, tint: section.tint)
                        }
                        .padding()
                        .frame(maxWidth: 700, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 12) {
                if page > 0 {
                    Button {
                        withAnimation { page -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 54, height: 54)
                            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .accessibilityLabel("Previous card")
                }
                Button(isLastCard ? (lesson.quiz.isEmpty ? "Finish lesson" : "Take the quiz") : "Continue") {
                    Haptics.tap()
                    if isLastCard {
                        if lesson.quiz.isEmpty { finishQuiz(score: 0) } else { phase = .quiz }
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(PrimaryButtonStyle(tint: section.tint))
            }
            .padding()
        }
    }

    private var isLastCard: Bool { page >= lesson.cards.count - 1 }

    // MARK: Flow

    private func finishQuiz(score: Int) {
        let total = lesson.quiz.count
        // Pass mark: at least half right. Beginners get encouragement, not punishment.
        if total == 0 || score * 2 >= total {
            let result = progress.completeLesson(lesson, in: section, course: courseStore.course,
                                                 score: score, total: total)
            Haptics.success()
            phase = .celebrate(result)
        } else {
            Haptics.error()
            phase = .retry(score: score, total: total)
        }
    }

    private var nextAccessibleLesson: Lesson? {
        guard let next = courseStore.nextLesson(after: lesson.id) else { return nil }
        guard next.section.isFree || subscriptions.hasAccess else { return nil }
        return next.lesson
    }

    private func goToNextLesson() {
        guard let next = courseStore.nextLesson(after: lesson.id) else { dismiss(); return }
        section = next.section
        lesson = next.lesson
        page = 0
        quizAttempt = 0
        phase = .learn
    }
}

// MARK: - Lesson card

struct LessonCardView: View {
    let card: LessonCard
    let tint: Color

    @Environment(\.openURL) var openURL
    @State var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch card.kind {
            case .text:
                cardTitle
                bodyText

            case .tip:
                callout(icon: "lightbulb.fill", label: "TIP", color: Theme.gold, background: Theme.goldSoft)

            case .warning:
                callout(icon: "exclamationmark.shield.fill", label: "HEADS UP", color: Theme.warning,
                        background: Theme.warning.opacity(0.12))

            case .steps:
                cardTitle
                bodyText
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array((card.items ?? []).enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.rounded(.subheadline, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(tint, in: Circle())
                            Text(item.markdown)
                                .font(.rounded(.body))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .card()

            case .example:
                cardTitle
                bodyText
                promptBox(label: "EXAMPLE PROMPT")

            case .compare:
                cardTitle
                bodyText
                compareBox(label: "VAGUE", text: card.bad ?? "", icon: "xmark.circle.fill",
                           color: Theme.danger, background: Theme.dangerSoft)
                compareBox(label: "CLEAR", text: card.good ?? "", icon: "checkmark.circle.fill",
                           color: Theme.success, background: Theme.successSoft)

            case .tryIt:
                HStack(spacing: 8) {
                    Image(systemName: "hand.point.right.fill")
                    Text("YOUR TURN")
                }
                .font(.rounded(.caption, weight: .heavy))
                .foregroundStyle(tint)
                cardTitle
                bodyText
                if card.prompt != nil {
                    promptBox(label: "TRY THIS PROMPT")
                    Button {
                        copyPrompt()
                        openURL(AppConfig.claudeURL(prefill: card.prompt))
                    } label: {
                        Label("Copy & try it in Claude", systemImage: "arrow.up.forward.app.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: tint))
                    Text("Come back here when you're done — your lesson will be waiting.")
                        .font(.rounded(.caption))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var cardTitle: some View {
        Text(card.title)
            .font(.rounded(.title2, weight: .bold))
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var bodyText: some View {
        if let body = card.body {
            Text(body.markdown)
                .font(.rounded(.body))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func callout(icon: String, label: String, color: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.rounded(.caption, weight: .heavy))
                .foregroundStyle(color)
            Text(card.title)
                .font(.rounded(.title3, weight: .bold))
            if let body = card.body {
                Text(body.markdown)
                    .font(.rounded(.body))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func promptBox(label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.rounded(.caption, weight: .heavy))
                    .foregroundStyle(tint)
                Spacer()
                Button {
                    copyPrompt()
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.rounded(.caption, weight: .bold))
                }
                .buttonStyle(.borderless)
            }
            Text(card.prompt ?? "")
                .font(.system(.body, design: .serif))
                .italic()
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(tint).frame(width: 4).padding(.vertical, 12)
        }
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
    }

    private func compareBox(label: String, text: String, icon: String, color: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.rounded(.caption, weight: .heavy))
                .foregroundStyle(color)
            Text(text)
                .font(.system(.body, design: .serif))
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func copyPrompt() {
        UIPasteboard.general.string = card.prompt
        Haptics.success()
        withAnimation { copied = true }
    }
}

// MARK: - Retry

struct RetryView: View {
    let score: Int
    let total: Int
    let tint: Color
    let onReview: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "arrow.clockwise.heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(tint)
            Text("So close!")
                .font(.rounded(.largeTitle, weight: .bold))
            Text("You got \(score) of \(total) right. Everyone learns by trying — a quick review and you'll have it.")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            VStack(spacing: 12) {
                Button("Try the quiz again", action: onRetry)
                    .buttonStyle(PrimaryButtonStyle(tint: tint))
                Button("Review the lesson", action: onReview)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
        }
        .padding()
    }
}
