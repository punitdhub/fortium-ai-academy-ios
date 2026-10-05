import SwiftUI

/// Four gentle welcome screens. Designed for people who have never used an AI app.
struct OnboardingView: View {
    @AppStorage(SettingsKey.hasOnboarded) var hasOnboarded = false
    @AppStorage(SettingsKey.userName) var userName = ""
    @AppStorage(SettingsKey.interests) var interestsRaw = ""
    @AppStorage(SettingsKey.largeText) var largeText = false

    @State var page = 0
    @FocusState var nameFocused: Bool

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
                ForEach(0..<4) { index in
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
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            Button(page == 3 ? "Start learning" : "Continue") {
                Haptics.tap()
                nameFocused = false
                if page < 3 {
                    withAnimation { page += 1 }
                } else {
                    hasOnboarded = true
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
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
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.gold)
                .frame(width: 28)
            Text(text)
                .font(.rounded(.body, weight: .medium))
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
    }
}
