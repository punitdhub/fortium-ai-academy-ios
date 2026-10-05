import SwiftUI

struct HomeView: View {
    var openBuilder: () -> Void

    @Environment(CourseStore.self) var courseStore
    @Environment(ProgressStore.self) var progress
    @Environment(SubscriptionStore.self) var subscriptions
    @AppStorage(SettingsKey.userName) var userName = ""

    @State var activeLesson: ActiveLesson?
    @State var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greeting
                    PromptBuilderHero(action: openBuilder)
                    continueCard
                    overallCard

                    Text("Your course")
                        .font(.rounded(.title2, weight: .bold))
                        .padding(.top, 4)

                    ForEach(Array(courseStore.sections.enumerated()), id: \.element.id) { index, section in
                        NavigationLink(value: section) {
                            SectionRow(number: index + 1, section: section,
                                       progress: progress.progress(for: section),
                                       completed: progress.completedCount(in: section),
                                       locked: !section.isFree && !subscriptions.hasAccess)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(AppConfig.disclaimer)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CourseSection.self) { section in
                SectionDetailView(section: section)
            }
            .fullScreenCover(item: $activeLesson) { active in
                LessonFlowView(section: active.section, lesson: active.lesson)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            #if DEBUG
            .onAppear {
                if ["lesson", "quiz", "celebration"].contains(Demo.screen ?? ""),
                   let section = courseStore.sections.dropFirst().first, let lesson = section.lessons.first {
                    activeLesson = ActiveLesson(section: section, lesson: lesson)
                }
                if Demo.is("paywall") { showPaywall = true }
            }
            #endif
        }
    }

    private var greeting: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.rounded(.title, weight: .bold))
                Text("Let's learn Claude, one small step at a time.")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StatChip(icon: "flame.fill", value: "\(progress.displayStreak)", tint: Color(hex: "#D9643A"))
                    .accessibilityLabel("\(progress.displayStreak) day streak")
                StatChip(icon: "star.fill", value: "\(progress.data.xp)", tint: Theme.gold)
                    .accessibilityLabel("\(progress.data.xp) experience points")
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let name = userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? base : "\(base), \(name)"
    }

    @ViewBuilder
    private var continueCard: some View {
        if let next = courseStore.firstIncomplete(completed: progress.data.completedLessons) {
            let locked = !next.section.isFree && !subscriptions.hasAccess
            Button {
                if locked { showPaywall = true } else { activeLesson = ActiveLesson(section: next.section, lesson: next.lesson) }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: locked ? "lock.fill" : "play.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(next.section.tint, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(progress.data.completedLessons.isEmpty ? "START HERE" : "CONTINUE LEARNING")
                            .font(.rounded(.caption, weight: .bold))
                            .foregroundStyle(next.section.tint)
                        Text(next.lesson.title)
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text("\(next.section.title) · \(next.lesson.minutes) min")
                            .font(.rounded(.caption))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                .card()
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 14) {
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.gold)
                Text("You've completed the whole course. Amazing work! 🎓")
                    .font(.rounded(.headline, weight: .semibold))
            }
            .card()
        }
    }

    private var overallCard: some View {
        let course = courseStore.course
        let value = progress.overallProgress(course)
        let done = progress.completedLessonCount(course)
        let total = courseStore.allLessons.count
        return HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: value, lineWidth: 9)
                Text("\(Int(value * 100))%")
                    .font(.rounded(.headline, weight: .bold))
            }
            .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text("Course progress")
                    .font(.rounded(.headline, weight: .bold))
                Text("\(done) of \(total) lessons complete")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.secondary)
                Text("\(progress.data.badges.count) of \(Badge.allCases.count) badges earned")
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .card()
    }
}

struct ActiveLesson: Identifiable {
    let section: CourseSection
    let lesson: Lesson
    var id: String { lesson.id }
}

struct StatChip: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(.rounded(.subheadline, weight: .bold)).monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke))
    }
}

/// The signature feature, pinned to the top of the home screen.
struct PromptBuilderHero: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color(hex: "#D9B779"))
                    Text("PROMPT BUILDER")
                        .font(.rounded(.caption, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: "#D9B779"))
                }
                Text("Not sure what to ask Claude?")
                    .font(.rounded(.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Text("Answer a few easy questions and get a ready-to-use prompt in about a minute.")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                HStack {
                    Text("Build a prompt")
                        .font(.rounded(.headline, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(Theme.brandDeep)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color(hex: "#D9B779"), in: Capsule())
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack(alignment: .topTrailing) {
                    Theme.heroGradient
                    Image(systemName: "sparkles")
                        .font(.system(size: 90))
                        .foregroundStyle(.white.opacity(0.08))
                        .offset(x: 10, y: -6)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Theme.brandDeep.opacity(0.25), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Prompt Builder")
    }
}

struct SectionRow: View {
    let number: Int
    let section: CourseSection
    let progress: Double
    let completed: Int
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(section.tint.gradient)
                Image(systemName: section.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("SECTION \(number)")
                        .font(.rounded(.caption2, weight: .bold))
                        .foregroundStyle(.secondary)
                    if section.isFree {
                        Text("FREE")
                            .font(.rounded(.caption2, weight: .heavy))
                            .foregroundStyle(Theme.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.successSoft, in: Capsule())
                    }
                }
                Text(section.title)
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                if progress >= 1 {
                    Label("Complete", systemImage: "checkmark.seal.fill")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.success)
                } else {
                    HStack(spacing: 8) {
                        ProgressBar(progress: progress, tint: section.tint, height: 6)
                        Text("\(completed)/\(section.lessons.count)")
                            .font(.rounded(.caption, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .foregroundStyle(locked ? Theme.gold : Color.secondary.opacity(0.6))
        }
        .card(padding: 14)
        .accessibilityElement(children: .combine)
    }
}
