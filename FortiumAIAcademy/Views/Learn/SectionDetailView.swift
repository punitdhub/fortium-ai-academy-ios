import SwiftUI

struct SectionDetailView: View {
    let section: CourseSection

    @Environment(ProgressStore.self) var progress
    @Environment(SubscriptionStore.self) var subscriptions
    @State var activeLesson: ActiveLesson?
    @State var showPaywall = false

    var locked: Bool { !section.isFree && !subscriptions.hasAccess }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if locked {
                    Button { showPaywall = true } label: {
                        Label("Unlock this section with Academy Pro", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                }

                ForEach(Array(section.lessons.enumerated()), id: \.element.id) { index, lesson in
                    Button {
                        Haptics.tap()
                        if locked { showPaywall = true } else { activeLesson = ActiveLesson(section: section, lesson: lesson) }
                    } label: {
                        LessonRow(index: index + 1, lesson: lesson, tint: section.tint,
                                  completed: progress.isCompleted(lesson),
                                  bestScore: progress.data.bestScores[lesson.id],
                                  locked: locked)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeLesson) { active in
            LessonFlowView(section: active.section, lesson: active.lesson)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: section.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(section.tint.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.rounded(.title2, weight: .bold))
                    Text("\(section.lessons.count) lessons · about \(section.totalMinutes) min")
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
            Text(section.subtitle)
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ProgressBar(progress: progress.progress(for: section), tint: section.tint, height: 10)
                Text("\(Int(progress.progress(for: section) * 100))%")
                    .font(.rounded(.subheadline, weight: .bold))
                    .monospacedDigit()
            }
        }
    }
}

struct LessonRow: View {
    let index: Int
    let lesson: Lesson
    let tint: Color
    let completed: Bool
    let bestScore: Int?
    let locked: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(completed ? Theme.success : tint.opacity(0.15))
                if completed {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index)")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(lesson.title)
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(lesson.summary)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 12) {
                    Label("\(lesson.minutes) min", systemImage: "clock")
                    Label("\(lesson.quiz.count)-question quiz", systemImage: "checklist")
                    if let bestScore, completed {
                        Label("\(bestScore)/\(lesson.quiz.count)", systemImage: "star.fill")
                            .foregroundStyle(Theme.gold)
                    }
                }
                .font(.rounded(.caption))
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if locked {
                Image(systemName: "lock.fill").foregroundStyle(Theme.gold)
            }
        }
        .card(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityValue(completed ? "Completed" : "")
    }
}
