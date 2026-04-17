import StoreKit
import SwiftUI
import Combine
import Security

@MainActor
class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Constants

    static let proMonthlyID   = "com.nominail.pro.monthly2"
    static let starterPackID  = "com.nominail.starter.pack"
    static let valuePackID    = "com.nominail.value.pack"

    static let monthlyLimit   = 40
    static let freeLimit      = 5
    static let starterPackGen = 5
    static let valuePackGen   = 20

    private static let keychainService  = "com.nominail.app"
    private static let freeGenKey       = "freeGenerationsUsed"
    private static let packBalanceKey   = "packGenerationsBalance"
    private static let monthlyUsedKey   = "monthlyGenerationsUsed"
    private static let cycleMonthKey    = "cycleMonth"
    private static let cycleYearKey     = "cycleYear"

    // MARK: - Published State

    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var isPurchasing = false

    // MARK: - Persistent Counters

    // freeGenerationsUsed is stored in Keychain so it survives app deletion/reinstall
    var freeGenerationsUsed: Int {
        get { keychainReadInt(Self.freeGenKey) ?? 0 }
        set {
            objectWillChange.send()
            keychainWriteInt(Self.freeGenKey, value: newValue)
        }
    }

    var packGenerationsBalance: Int {
        get { keychainReadInt(Self.packBalanceKey) ?? 0 }
        set { objectWillChange.send(); keychainWriteInt(Self.packBalanceKey, value: newValue) }
    }

    var monthlyGenerationsUsed: Int {
        get { keychainReadInt(Self.monthlyUsedKey) ?? 0 }
        set { objectWillChange.send(); keychainWriteInt(Self.monthlyUsedKey, value: newValue) }
    }

    var cycleMonth: Int {
        get { keychainReadInt(Self.cycleMonthKey) ?? Calendar.current.component(.month, from: Date()) }
        set { keychainWriteInt(Self.cycleMonthKey, value: newValue) }
    }

    var cycleYear: Int {
        get { keychainReadInt(Self.cycleYearKey) ?? Calendar.current.component(.year, from: Date()) }
        set { keychainWriteInt(Self.cycleYearKey, value: newValue) }
    }

    // MARK: - Lifecycle

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        // One-time migration: move all counters from UserDefaults → Keychain
        // so they survive app deletion and reinstall.
        let migrations: [(String, String)] = [
            ("freeGenerationsUsed",    Self.freeGenKey),
            ("packGenerationsBalance", Self.packBalanceKey),
            ("monthlyGenerationsUsed", Self.monthlyUsedKey),
            ("cycleMonth",             Self.cycleMonthKey),
            ("cycleYear",              Self.cycleYearKey)
        ]
        for (udKey, kcKey) in migrations {
            if keychainReadInt(kcKey) == nil {
                let legacy = UserDefaults.standard.integer(forKey: udKey)
                keychainWriteInt(kcKey, value: legacy)
            }
        }

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
        }
        return freeGenerationsUsed < Self.freeLimit || packGenerationsBalance > 0
    }

    var generationsRemaining: Int {
        if isSubscribed {
            resetCycleIfNeeded()
            return max(0, Self.monthlyLimit - monthlyGenerationsUsed)
        }
        let freeLeft = max(0, Self.freeLimit - freeGenerationsUsed)
        return freeLeft + packGenerationsBalance
    }

    func recordGeneration() {
        if isSubscribed {
            monthlyGenerationsUsed += 1
        } else if freeGenerationsUsed < Self.freeLimit {
            freeGenerationsUsed += 1
        } else if packGenerationsBalance > 0 {
            packGenerationsBalance -= 1
        }
    }

    // MARK: - Cycle Reset

    private func resetCycleIfNeeded() {
        let now   = Date()
        let month = Calendar.current.component(.month, from: now)
        let year  = Calendar.current.component(.year,  from: now)
        if month != cycleMonth || year != cycleYear {
            monthlyGenerationsUsed = 0
            cycleMonth = month
            cycleYear  = year
        }
    }

    // MARK: - StoreKit

    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                Self.proMonthlyID,
                Self.starterPackID,
                Self.valuePackID
            ])
        } catch {
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func purchase(productID: String) async {
        guard let product = product(for: productID) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                // Credit pack generations
                switch productID {
                case Self.starterPackID: packGenerationsBalance += Self.starterPackGen
                case Self.valuePackID:   packGenerationsBalance += Self.valuePackGen
                default: break
                }
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

    // Convenience for existing paywall subscribe button
    func purchase() async {
        await purchase(productID: Self.proMonthlyID)
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

    // MARK: - Keychain Helpers

    private func keychainReadInt(_ key: String) -> Int? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str  = String(data: data, encoding: .utf8),
              let value = Int(str) else { return nil }
        return value
    }

    private func keychainWriteInt(_ key: String, value: Int) {
        let data = Data(String(value).utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}
