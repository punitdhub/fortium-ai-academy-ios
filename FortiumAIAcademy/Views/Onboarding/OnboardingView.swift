import SwiftUI

/// Five gentle welcome screens. Designed for people who have never used an AI app.
struct OnboardingView: View {
    @AppStorage(SettingsKey.hasOnboarded) var hasOnboarded = false
    @AppStorage(SettingsKey.userName) var userName = ""
    @AppStorage(SettingsKey.interests) var interestsRaw = ""
    @AppStorage(SettingsKey.largeText) var largeText = false

    @Environment(ReminderManager.self) var reminders

    @State var page = 0
    @State var wantsReminder = true
    @State var reminderTime = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
    @FocusState var nameFocused: Bool

    private let lastPage = 4

    struct Interest: Hashable {
        let title: String
        let icon: String
    }

    private let interestOptions = [
        Interest(title: "My job", icon: "briefcase.fill"),
        Interest(title: "My business", icon: "storefront.fill"),
        Interest(title: "Personal life", icon: "house.fill"),
        Interest(title: "Studying", icon: "book.fill"),
        Interest(title: "Just curious", icon: "sparkles"),
    ]

    private var interests: Set<String> {
        Set(interestsRaw.split(separator: "|").map(String.init))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0...lastPage, id: \.self) { index in
                    Capsule()
                        .fill(index <= page ? Theme.gold : Theme.surfaceRaised)
                        .frame(height: 5)
                }
            }
            .padding()

            TabView(selection: $page) {
                welcome.tag(0)
                interestsPage.tag(1)
                comfortPage.tag(2)
                namePage.tag(3)
                reminderPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            Button(page == lastPage ? "Start learning" : "Continue") {
                Haptics.tap()
                nameFocused = false
                if page < lastPage {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        #if DEBUG
        .onAppear { if Demo.is("reminder") { page = lastPage } }
        #endif
    }

    private func finish() {
        Task {
            if wantsReminder {
                reminders.setTime(reminderTime)
                await reminders.enable() // shows the iOS permission prompt
            }
            hasOnboarded = true
        }
    }

    private var reminderPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Theme.goldGradient).frame(width: 88, height: 88)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            Text("Build a daily habit")
                .font(.rounded(.largeTitle, weight: .bold))
            Text("People who practice a little each day remember much more. Would you like a friendly daily reminder?")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                Toggle(isOn: $wantsReminder) {
                    Label("Remind me every day", systemImage: "bell.fill")
                        .font(.rounded(.headline, weight: .semibold))
                }
                .tint(Theme.gold)
                .padding(.vertical, 6)
                if wantsReminder {
                    Divider().padding(.vertical, 8)
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .font(.rounded(.headline, weight: .semibold))
                }
            }
            .card()
            .animation(.easeInOut, value: wantsReminder)

            TipRow(text: "We'll skip the reminder on days you've already learned, and you can change or turn it off anytime in Settings.")
            Spacer()
        }
        .padding()
        .scrollablePage()
    }

    private var welcome: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Theme.heroGradient)
                    .frame(width: 140, height: 140)
                Image(systemName: "sparkles")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Color(hex: "#D9B779"))
            }
            Text("Welcome to\nFortium AI Academy")
                .font(.rounded(.largeTitle, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Learn to use Claude, the AI assistant, step by step. No tech skills needed — we'll explain everything in plain English.")
                .font(.rounded(.title3))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 12) {
                feature("wand.and.stars", "A Prompt Builder that writes great prompts for you")
                feature("graduationcap.fill", "Short lessons — about 5 minutes each")
                feature("trophy.fill", "Quizzes, badges and celebrations as you go")
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .scrollablePage()
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.gold)
                .frame(width: 28)
            Text(text)
                .font(.rounded(.body, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var interestsPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("What would you like Claude to help with?")
                .font(.rounded(.largeTitle, weight: .bold))
            Text("Pick as many as you like. We'll use this to suggest examples.")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                ForEach(interestOptions, id: \.self) { option in
                    let selected = interests.contains(option.title)
                    Button {
                        Haptics.tap()
                        var updated = interests
                        if selected { updated.remove(option.title) } else { updated.insert(option.title) }
                        interestsRaw = updated.sorted().joined(separator: "|")
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option.icon)
                                .font(.title3)
                                .foregroundStyle(selected ? .white : Theme.brand)
                                .frame(width: 44, height: 44)
                                .background(selected ? Theme.brandMid : Theme.surfaceRaised,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text(option.title)
                                .font(.rounded(.headline, weight: .semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected ? Theme.gold : .secondary)
                        }
                        .card(padding: 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            Spacer()
        }
        .padding()
        .scrollablePage()
    }

    private var comfortPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Make reading comfortable")
                .font(.rounded(.largeTitle, weight: .bold))
            Text("Would you like larger text throughout the app? You can change this anytime in Settings.")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                textChoice(title: "Standard text", sample: "This is how lessons will look.", large: false)
                textChoice(title: "Larger text", sample: "This is how lessons will look.", large: true)
            }
            Spacer()
        }
        .padding()
        .scrollablePage()
    }

    private func textChoice(title: String, sample: String, large: Bool) -> some View {
        Button {
            Haptics.tap()
            largeText = large
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.rounded(.headline, weight: .bold))
                    Text(sample)
                        .font(.system(size: large ? 22 : 17))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: largeText == large ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(largeText == large ? Theme.gold : .secondary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    private var namePage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("What should we call you?")
                .font(.rounded(.largeTitle, weight: .bold))
            Text("Optional — we'll use it to greet you and on your certificate.")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
            TextField("Your first name", text: $userName)
                .font(.rounded(.title3))
                .textContentType(.givenName)
                .submitLabel(.done)
                .focused($nameFocused)
                .padding(16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.stroke))
            TipRow(text: "Your progress stays private on this device. We never see your conversations with Claude.")
            Spacer()
        }
        .padding()
        .scrollablePage()
    }
}

private extension View {
    /// Keeps onboarding pages vertically centered, but scrollable when text is large.
    func scrollablePage() -> some View {
        GeometryReader { geo in
            ScrollView {
                self.frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
