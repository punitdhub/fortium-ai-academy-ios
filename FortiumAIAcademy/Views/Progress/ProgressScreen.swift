import SwiftUI

struct ProgressScreen: View {
    @Environment(CourseStore.self) var courseStore
    @Environment(ProgressStore.self) var progress
    @State var showCertificate = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summary

                    HStack(spacing: 12) {
                        StatTile(icon: "flame.fill", value: "\(progress.displayStreak)", label: "Day streak",
                                 tint: Color(hex: "#D9643A"))
                        StatTile(icon: "star.fill", value: "\(progress.data.xp)", label: "Total XP", tint: Theme.gold)
                        StatTile(icon: "trophy.fill", value: "\(progress.data.longestStreak)", label: "Best streak",
                                 tint: Theme.brandMid)
                    }

                    certificateCard

                    Text("Badges")
                        .font(.rounded(.title2, weight: .bold))
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(Badge.allCases) { badge in
                            let earned = progress.hasBadge(badge)
                            VStack(spacing: 8) {
                                BadgeIcon(badge: badge, earned: earned, size: 66)
                                Text(badge.title)
                                    .font(.rounded(.caption, weight: .bold))
                                    .multilineTextAlignment(.center)
                                Text(badge.detail)
                                    .font(.rounded(.caption2))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }
                            .opacity(earned ? 1 : 0.7)
                        }
                    }
                    .card()

                    Text("Sections")
                        .font(.rounded(.title2, weight: .bold))
                    VStack(spacing: 12) {
                        ForEach(courseStore.sections) { section in
                            HStack(spacing: 12) {
                                Image(systemName: section.icon)
                                    .foregroundStyle(section.tint)
                                    .frame(width: 28)
                                Text(section.title)
                                    .font(.rounded(.subheadline, weight: .semibold))
                                    .lineLimit(1)
                                Spacer()
                                ProgressBar(progress: progress.progress(for: section), tint: section.tint, height: 6)
                                    .frame(width: 80)
                                Text("\(progress.completedCount(in: section))/\(section.lessons.count)")
                                    .font(.rounded(.caption, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .frame(width: 32, alignment: .trailing)
                            }
                        }
                    }
                    .card()
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Your progress")
            .sheet(isPresented: $showCertificate) { CertificateSheet() }
        }
    }

    private var summary: some View {
        let value = progress.overallProgress(courseStore.course)
        return HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: value, lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(Int(value * 100))%")
                        .font(.rounded(.title, weight: .bold))
                    Text("done")
                        .font(.rounded(.caption))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 110)
            VStack(alignment: .leading, spacing: 6) {
                Text(levelTitle)
                    .font(.rounded(.title3, weight: .bold))
                Text("\(progress.completedLessonCount(courseStore.course)) of \(courseStore.allLessons.count) lessons")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.secondary)
                Text("\(progress.data.badges.count) badges · \(progress.data.promptsBuilt) prompts built")
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    /// A friendly "level" based on XP, so progress always feels like it's moving.
    private var levelTitle: String {
        switch progress.data.xp {
        case ..<100: "Curious Beginner"
        case ..<500: "Confident Explorer"
        case ..<1200: "Skilled Prompter"
        case ..<2500: "Claude Power User"
        default: "AI Academy Master"
        }
    }

    @ViewBuilder
    private var certificateCard: some View {
        let graduated = progress.data.graduationDate != nil
        Button {
            if graduated { showCertificate = true }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: graduated ? "doc.richtext.fill" : "lock.doc.fill")
                    .font(.title)
                    .foregroundStyle(graduated ? Theme.gold : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certificate of Completion")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(graduated ? "Tap to view and share your certificate."
                                   : "Finish every lesson to earn your certificate.")
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if graduated { Image(systemName: "chevron.right").foregroundStyle(.tertiary) }
            }
            .card()
        }
        .buttonStyle(.plain)
        .disabled(!graduated)
    }
}

// MARK: - Certificate

struct CertificateSheet: View {
    @Environment(ProgressStore.self) var progress
    @Environment(\.dismiss) var dismiss
    @AppStorage(SettingsKey.userName) var userName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CertificateView(name: displayName, date: progress.data.graduationDate ?? Date())
                        .padding(.top)
                    if let image = renderedImage {
                        ShareLink(item: image, preview: SharePreview("My Fortium AI Academy certificate", image: image)) {
                            Label("Share certificate", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    }
                    if userName.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Tip: add your name in Settings so it appears on your certificate.")
                            .font(.rounded(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var displayName: String {
        let name = userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Academy Graduate" : name
    }

    @MainActor
    private var renderedImage: Image? {
        let renderer = ImageRenderer(content:
            CertificateView(name: displayName, date: progress.data.graduationDate ?? Date())
                .frame(width: 600)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

struct CertificateView: View {
    let name: String
    let date: Date

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "#A87F40"))
            Text("CERTIFICATE OF COMPLETION")
                .font(.system(.caption, design: .serif, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color(hex: "#4A6C8C"))
            Text("This certifies that")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Color(hex: "#5A6270"))
            Text(name)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(Color(hex: "#1E2B3A"))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
            Rectangle()
                .fill(Color(hex: "#D9B779"))
                .frame(width: 160, height: 2)
            Text("has completed the course")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Color(hex: "#5A6270"))
            Text("Claude AI Essentials")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Color(hex: "#1E2B3A"))
            Text(date.formatted(date: .long, time: .omitted))
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(Color(hex: "#5A6270"))
                .padding(.top, 4)
            Text("FORTIUM AI ACADEMY")
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .tracking(1.5)
                .foregroundStyle(Color(hex: "#A87F40"))
                .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#FFFDF8"))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(hex: "#D9B779"), lineWidth: 3)
                .padding(8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color(hex: "#D9B779").opacity(0.5), lineWidth: 1)
                .padding(14)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}
