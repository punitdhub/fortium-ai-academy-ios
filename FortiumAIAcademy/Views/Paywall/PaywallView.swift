import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStore.self) var store
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State var selectedID: String = AppConfig.yearlyProductID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefits
                    plans
                    purchaseButton
                    legal
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
            .task { await store.loadProducts() }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.goldGradient).frame(width: 88, height: 88)
                Image(systemName: "crown.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            }
            Text("Unlock the full Academy")
                .font(.rounded(.largeTitle, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Become confident with every Claude feature — at your own pace.")
                .font(.rounded(.body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefit("books.vertical.fill", "Every section & lesson", "Projects, Artifacts, Research, Connectors, Cowork and more")
            benefit("wand.and.stars", "All 14 Prompt Builder goals", "Emails, plans, presentations, data, career help…")
            benefit("graduationcap.fill", "Certificate of completion", "Share your achievement on LinkedIn")
            benefit("arrow.triangle.2.circlepath", "Always up to date", "New lessons as Claude adds features")
        }
        .card()
    }

    private func benefit(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.gold)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.rounded(.headline, weight: .bold))
                Text(detail).font(.rounded(.subheadline)).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var plans: some View {
        if store.products.isEmpty {
            VStack(spacing: 10) {
                if store.isLoadingProducts {
                    ProgressView()
                } else {
                    Text("Subscription options are unavailable right now.")
                        .font(.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                    Button("Try again") { Task { await store.loadProducts() } }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(spacing: 12) {
                ForEach(store.products.sorted { $0.price > $1.price }, id: \.id) { product in
                    PlanRow(product: product,
                            isSelected: selectedID == product.id,
                            badge: product.id == AppConfig.yearlyProductID ? savingsBadge : nil,
                            monthlyEquivalent: store.monthlyEquivalent(of: product),
                            showTrial: store.trialEligible)
                        .onTapGesture {
                            Haptics.tap()
                            selectedID = product.id
                        }
                }
            }
        }
    }

    private var savingsBadge: String {
        if let percent = store.savingsPercent(), percent > 0 { return "SAVE \(percent)%" }
        return "BEST VALUE"
    }

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedID } ?? store.products.first
    }

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    if await store.purchase(product) {
                        Haptics.success()
                        dismiss()
                    }
                }
            } label: {
                if store.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
            .disabled(selectedProduct == nil || store.isPurchasing)

            if let product = selectedProduct {
                Text(priceLine(for: product))
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var ctaTitle: String {
        if store.trialEligible, selectedProduct?.trialDescription != nil { return "Start my free trial" }
        return "Subscribe"
    }

    private func priceLine(for product: Product) -> String {
        let renew = "\(product.displayPrice)/\(product.periodLabel)"
        if store.trialEligible, let trial = product.trialDescription {
            return "\(trial), then \(renew). Cancel anytime."
        }
        return "\(renew). Cancel anytime."
    }

    private var legal: some View {
        VStack(spacing: 10) {
            Button("Restore purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.rounded(.subheadline, weight: .semibold))

            Text("Payment is charged to your Apple ID at confirmation of purchase. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Button("Terms of Use") { openURL(AppConfig.termsURL) }
                Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
            }
            .font(.caption)
        }
    }
}

struct PlanRow: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let monthlyEquivalent: String?
    let showTrial: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? Theme.gold : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(product.periodLabel == "year" ? "Yearly" : "Monthly")
                        .font(.rounded(.headline, weight: .bold))
                    if let badge {
                        Text(badge)
                            .font(.rounded(.caption2, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.success, in: Capsule())
                    }
                }
                if showTrial, let trial = product.trialDescription {
                    Text(trial)
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(product.displayPrice)
                    .font(.rounded(.headline, weight: .bold))
                Text(monthlyEquivalent ?? "per \(product.periodLabel)")
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? Theme.gold : Theme.stroke, lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
