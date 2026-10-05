import SwiftUI

/// The "win" screen after a lesson: confetti, XP count-up, badges, section/course milestones.
struct CelebrationView: View {
    let result: LessonResult
    let section: CourseSection
    let lesson: Lesson
    let nextLesson: Lesson?
    let onNext: () -> Void
    let onDone: () -> Void

    @State var shownXP = 0
    @State var appeared = false
    @State var showCertificate = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 22) {
                    trophy
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text(headline)
                            .font(.rounded(.largeTitle, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(subheadline)
                            .font(.rounded(.body))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        StatTile(icon: "star.fill", value: "+\(shownXP)", label: "XP earned", tint: Theme.gold)
                        if result.total > 0 {
                            StatTile(icon: "checkmark.circle.fill", value: "\(result.score)/\(result.total)",
                                     label: "Quiz score", tint: Theme.success)
                        }
                        StatTile(icon: "flame.fill", value: "\(result.streak)",
                                 label: "Day streak", tint: Color(hex: "#D9643A"))
                    }

                    if let finished = result.completedSection {
                        milestoneCard(icon: "rosette", color: finished.tint,
                                      title: "Section complete!",
                                      detail: "You've finished \"\(finished.title)\". +\(XP.sectionBonus) bonus XP")
                    }

                    if result.completedCourse {
                        milestoneCard(icon: "graduationcap.fill", color: Theme.gold,
                                      title: "You graduated! 🎓",
                                      detail: "You completed the entire Academy. Your certificate is ready.")
                        Button {
                            showCertificate = true
                        } label: {
                            Label("View my certificate", systemImage: "doc.richtext")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    }

                    if !result.newBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(result.newBadges.count == 1 ? "New badge unlocked" : "New badges unlocked")
                                .font(.rounded(.headline, weight: .bold))
                            ForEach(result.newBadges) { badge in
                                HStack(spacing: 14) {
                                    BadgeIcon(badge: badge, earned: true, size: 50)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(badge.title).font(.rounded(.headline, weight: .bold))
                                        Text(badge.detail).font(.rounded(.subheadline)).foregroundStyle(.secondary)
                                    }
                                }
                                .scaleEffect(appeared ? 1 : 0.6)
                                .opacity(appeared ? 1 : 0)
                            }
                        }
                        .card()
                    }
                }
                .padding()
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }

            ConfettiView(count: result.completedSection != nil || result.completedCourse ? 220 : 120)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let nextLesson {
                    Button {
                        onNext()
                    } label: {
                        Label("Next: \(nextLesson.title)", systemImage: "arrow.right")
                            .lineLimit(1)
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: section.tint))
                    Button("Back to course", action: onDone)
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Back to course", action: onDone)
                        .buttonStyle(PrimaryButtonStyle(tint: section.tint))
                }
            }
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $showCertificate) { CertificateSheet() }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) { appeared = true }
            countUpXP()
        }
    }

    private var trophy: some View {
        ZStack {
            Circle()
                .fill(Theme.goldGradient)
                .frame(width: 130, height: 130)
                .shadow(color: Theme.gold.opacity(0.5), radius: 20)
            Image(systemName: result.completedCourse ? "graduationcap.fill"
                  : result.completedSection != nil ? "trophy.fill"
                  : result.isPerfect ? "star.fill" : "checkmark")
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(.white)
        }
        .scaleEffect(appeared ? 1 : 0.3)
        .rotationEffect(.degrees(appeared ? 0 : -30))
        .accessibilityHidden(true)
    }

    private var headline: String {
        if result.completedCourse { return "Congratulations!" }
        if result.completedSection != nil { return "Section mastered!" }
        if result.isPerfect { return "Perfect score!" }
        return ["Lesson complete!", "Well done!", "Great job!"][lesson.id.count % 3]
    }

    private var subheadline: String {
        if result.isFirstCompletion {
            return "You finished \"\(lesson.title)\". Every lesson makes Claude more useful to you."
        }
        return "Nice refresher on \"\(lesson.title)\"."
    }

    private func milestoneCard(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.rounded(.headline, weight: .bold))
                Text(detail).font(.rounded(.subheadline)).foregroundStyle(.secondary)
            }
        }
        .card()
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
    }

    private func countUpXP() {
        let target = result.xpEarned
        guard target > 0 else { return }
        let steps = 30
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(step) * 0.03) {
                shownXP = Int(Double(target) * Double(step) / Double(steps))
            }
        }
    }
}

struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.rounded(.title2, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.rounded(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.stroke))
        .accessibilityElement(children: .combine)
    }
}

struct BadgeIcon: View {
    let badge: Badge
    let earned: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(earned ? AnyShapeStyle(badge.color.gradient) : AnyShapeStyle(Theme.surfaceRaised))
            Circle()
                .strokeBorder(earned ? Color.white.opacity(0.35) : Theme.stroke, lineWidth: size * 0.05)
                .padding(size * 0.06)
            Image(systemName: earned ? badge.icon : "lock.fill")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(earned ? Color.white : Color.secondary.opacity(0.6))
        }
        .frame(width: size, height: size)
        .accessibilityLabel(badge.title + (earned ? ", earned" : ", locked"))
    }
}
