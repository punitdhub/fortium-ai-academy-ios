import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionStore.self) var store
    @Environment(ProgressStore.self) var progress
    @Environment(\.openURL) var openURL

    @AppStorage(SettingsKey.userName) var userName = ""
    @AppStorage(SettingsKey.largeText) var largeText = false
    @AppStorage(SettingsKey.haptics) var haptics = true
    @AppStorage(SettingsKey.celebrations) var celebrations = true
    @AppStorage(SettingsKey.hasOnboarded) var hasOnboarded = true

    @State var showPaywall = false
    @State var showManage = false
    @State var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your name") {
                    TextField("First name (shown on your certificate)", text: $userName)
                        .textContentType(.givenName)
                }

                Section {
                    Toggle("Larger text", isOn: $largeText)
                    Toggle("Vibration feedback", isOn: $haptics)
                    Toggle("Celebration effects", isOn: $celebrations)
                } header: {
                    Text("Comfort")
                } footer: {
                    Text("Larger text makes lessons easier to read. You can also change text size for all apps in the iPhone Settings app under Display & Brightness.")
                }

                Section("Academy Pro") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(store.hasAccess ? "Active" : "Free plan")
                            .foregroundStyle(store.hasAccess ? Theme.success : .secondary)
                            .fontWeight(.semibold)
                    }
                    if store.isPro {
                        Button("Manage subscription") { showManage = true }
                    } else {
                        Button("Upgrade to Academy Pro") { showPaywall = true }
                            .fontWeight(.semibold)
                    }
                    Button("Restore purchases") {
                        Task { await store.restorePurchases() }
                    }
                }

                Section {
                    Button("Show welcome screens again") { hasOnboarded = false }
                    Button("Reset my progress", role: .destructive) { confirmReset = true }
                } header: {
                    Text("Progress")
                }

                Section("About") {
                    Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
                    Button("Terms of Use") { openURL(AppConfig.termsURL) }
                    if let mail = URL(string: "mailto:\(AppConfig.supportEmail)") {
                        Button("Contact support") { openURL(mail) }
                    }
                    Text(AppConfig.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                #if DEBUG
                Section {
                    Toggle("Unlock Pro (testing only)", isOn: Binding(
                        get: { store.debugUnlock },
                        set: { store.debugUnlock = $0 }
                    ))
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Only visible in debug builds from Xcode. Never shipped to the App Store.")
                }
                #endif
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .manageSubscriptionsSheet(isPresented: $showManage)
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset progress", role: .destructive) { progress.reset() }
            } message: {
                Text("This clears your completed lessons, XP, streak and badges. Saved prompts are kept.")
            }
            .alert("Purchases", isPresented: Binding(
                get: { store.errorMessage != nil && !showPaywall },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }
}
