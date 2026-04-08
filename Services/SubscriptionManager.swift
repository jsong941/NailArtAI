import StoreKit
import SwiftUI
import Combine

@MainActor
class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Constants

    static let proMonthlyID = "com.vernis.pro.monthly"
    static let monthlyLimit = 20
    static let freeLimit = 400

    // MARK: - Published State

    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var isPurchasing = false

    // MARK: - Persistent Counters

    @AppStorage("freeGenerationsUsed") var freeGenerationsUsed = 0
    @AppStorage("monthlyGenerationsUsed") var monthlyGenerationsUsed = 0
    @AppStorage("cycleMonth") var cycleMonth = Calendar.current.component(.month, from: Date())
    @AppStorage("cycleYear") var cycleYear = Calendar.current.component(.year, from: Date())

    // MARK: - Lifecycle

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshSubscriptionStatus()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Generation Access

    var canGenerate: Bool {
        if isSubscribed {
            resetCycleIfNeeded()
            return monthlyGenerationsUsed < Self.monthlyLimit
        } else {
            return freeGenerationsUsed < Self.freeLimit
        }
    }

    var generationsRemaining: Int {
        if isSubscribed {
            resetCycleIfNeeded()
            return max(0, Self.monthlyLimit - monthlyGenerationsUsed)
        } else {
            return max(0, Self.freeLimit - freeGenerationsUsed)
        }
    }

    func recordGeneration() {
        if isSubscribed {
            monthlyGenerationsUsed += 1
        } else {
            freeGenerationsUsed += 1
        }
    }

    // MARK: - Cycle Reset

    private func resetCycleIfNeeded() {
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let year = Calendar.current.component(.year, from: now)
        if month != cycleMonth || year != cycleYear {
            monthlyGenerationsUsed = 0
            cycleMonth = month
            cycleYear = year
        }
    }

    // MARK: - StoreKit

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.proMonthlyID])
        } catch {
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    func purchase() async {
        guard let product = products.first else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshSubscriptionStatus()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("[StoreKit] Purchase failed: \(error)")
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("[StoreKit] Restore failed: \(error)")
        }
        await refreshSubscriptionStatus()
    }

    func refreshSubscriptionStatus() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.proMonthlyID,
               transaction.revocationDate == nil {
                found = true
                break
            }
        }
        isSubscribed = found
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Verification

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.userCancelled
        case .verified(let value):
            return value
        }
    }
}
