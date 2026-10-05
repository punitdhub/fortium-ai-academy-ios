import SwiftUI

@main
struct FortiumAIAcademyApp: App {
    @State private var courseStore = CourseStore()
    @State private var progressStore = ProgressStore()
    @State private var subscriptionStore = SubscriptionStore()
    @State private var promptLibrary = PromptLibrary()
    @State private var reminders = ReminderManager()

    init() {
        UserDefaults.standard.register(defaults: [
            SettingsKey.haptics: true,
            SettingsKey.celebrations: true,
            SettingsKey.largeText: false,
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(courseStore)
                .environment(progressStore)
                .environment(subscriptionStore)
                .environment(promptLibrary)
                .environment(reminders)
        }
    }
}

struct RootView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(SettingsKey.largeText) private var largeText = false
    @Environment(ProgressStore.self) private var progress
    @Environment(CourseStore.self) private var courseStore
    @Environment(ReminderManager.self) private var reminders
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Theme.brand)
        .modifier(LargeTextModifier(enabled: largeText))
        .onAppear {
            progress.registerVisit()
            updateReminders()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                progress.registerVisit()
                updateReminders()
            }
        }
        // Any lesson or prompt updates lastActiveDay, so reminders always reflect today.
        .onChange(of: progress.data.lastActiveDay) { _, _ in updateReminders() }
    }

    private func updateReminders() {
        let next = courseStore.firstIncomplete(completed: progress.data.completedLessons)
        reminders.update(context: .init(lastActiveDay: progress.data.lastActiveDay,
                                        streak: progress.displayStreak,
                                        nextLessonTitle: next?.lesson.title))
    }
}

/// "Comfort mode": bumps the text size for learners who prefer larger type,
/// while still honoring the system Dynamic Type setting when it is even larger.
struct LargeTextModifier: ViewModifier {
    let enabled: Bool
    @Environment(\.dynamicTypeSize) var systemSize

    func body(content: Content) -> some View {
        if enabled && systemSize < .xxLarge {
            content.dynamicTypeSize(.xxLarge)
        } else {
            content
        }
    }
}

struct MainTabView: View {
    enum Tab: Hashable { case learn, build, progress, settings }
    @State private var selection: Tab = Self.initialTab

    private static var initialTab: Tab {
        #if DEBUG
        switch Demo.screen {
        case "builder", "wizard": return .build
        case "progress": return .progress
        case "settings": return .settings
        default: return .learn
        }
        #else
        return .learn
        #endif
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(openBuilder: { selection = .build })
                .tabItem { Label("Learn", systemImage: "graduationcap.fill") }
                .tag(Tab.learn)

            NavigationStack { PromptBuilderView() }
                .tabItem { Label("Prompt Builder", systemImage: "wand.and.stars") }
                .tag(Tab.build)

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "trophy.fill") }
                .tag(Tab.progress)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
    }
}
