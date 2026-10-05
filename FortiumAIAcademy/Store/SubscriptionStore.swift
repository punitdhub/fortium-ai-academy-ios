import StoreKit
import SwiftUI

/// StoreKit 2 subscription handling for "Academy Pro".
///
/// To test without an Apple Developer account, run from Xcode: the shared scheme
/// uses Products.storekit, so purchases are simulated locally.
@MainActor
@Observable
final class SubscriptionStore {
    static let productIDs = [AppConfig.monthlyProductID, AppConfig.yearlyProductID]

    private(set) var products: [Product] = []
    private(set) var isPro = false
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var trialEligible = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    /// Debug builds can force Pro on from Settings to preview locked content.
    var debugUnlock = UserDefaults.standard.bool(forKey: SettingsKey.debugUnlockPro) {
        didSet { UserDefaults.standard.set(debugUnlock, forKey: SettingsKey.debugUnlockPro) }
    }

    /// Whether premium content is unlocked.
    var hasAccess: Bool {
        #if DEBUG
        if debugUnlock { return true }
        #endif
        return isPro
    }

    var monthly: Product? { products.first { $0.id == AppConfig.monthlyProductID } }
    var yearly: Product? { products.first { $0.id == AppConfig.yearlyProductID } }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            if let subscription = yearly?.subscription ?? monthly?.subscription {
                trialEligible = await subscription.isEligibleForIntroOffer
            }
        } catch {
            errorMessage = "Couldn't load subscription options. Please check your connection and try again."
        }
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "We couldn't verify that purchase with the App Store."
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Restore didn't complete. Please try again."
        }
        await refreshEntitlements()
        if !isPro && errorMessage == nil {
            errorMessage = "No active subscription was found for this Apple ID."
        }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    /// e.g. "$2.50/mo" for the yearly plan, to show the savings.
    func monthlyEquivalent(of product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod, period.unit == .year else { return nil }
        let perMonth = product.price / 12
        return perMonth.formatted(product.priceFormatStyle) + "/mo"
    }

    func savingsPercent() -> Int? {
        guard let monthly, let yearly else { return nil }
        let fullYear = monthly.price * 12
        guard fullYear > 0 else { return nil }
        let saving = (fullYear - yearly.price) / fullYear * 100
        return Int(NSDecimalNumber(decimal: saving).doubleValue.rounded())
    }
}

extension Product {
    var periodLabel: String {
        guard let period = subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .day: return period.value == 7 ? "week" : "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return ""
        }
    }

    var trialDescription: String? {
        guard let offer = subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let period = offer.period
        switch period.unit {
        case .day: return "\(period.value)-day free trial"
        case .week: return "\(period.value * 7)-day free trial"
        case .month: return "\(period.value)-month free trial"
        case .year: return "\(period.value)-year free trial"
        @unknown default: return "Free trial"
        }
    }
}
