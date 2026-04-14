//
//  GameCreditsManager.swift
//  ChessApp
//
//  Manages game credits, free trial, and StoreKit 2 purchases.
//

import Foundation
import Observation
import StoreKit

// MARK: - Product IDs

enum GameProduct {
    static let fiveGamePack = "com.cwang.chessmentor.games5pack"
    static let allProductIDs: Set<String> = [fiveGamePack]
}

// MARK: - GameCreditsManager

@Observable
class GameCreditsManager: @unchecked Sendable {

    // MARK: - Purchase State

    var products: [Product] = []
    var isPurchasing = false
    var purchaseError: String?
    var isLoadingProducts = false
    var productsLoadError: String?

    // MARK: - Credits State

    private(set) var remainingCredits: Int {
        didSet {
            UserDefaults.standard.set(remainingCredits, forKey: Keys.gameCredits)
        }
    }

    private(set) var freeGamesUsedToday: Int {
        didSet {
            UserDefaults.standard.set(freeGamesUsedToday, forKey: Keys.freeGamesUsedToday)
        }
    }

    private let installDate: Date

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Error>?

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let installDate = "ChessCoach.installDate"
        static let gameCredits = "ChessCoach.gameCredits"
        static let freeGamesUsedToday = "ChessCoach.freeGamesUsedToday"
        static let lastFreeGameDate = "ChessCoach.lastFreeGameDate"
    }

    // MARK: - Free Trial Configuration

    private static let freeTrialMonths = 3
    private static let freeGamesPerDay = 1
    static let creditsPerPurchase = 5

    // MARK: - Computed Properties

    var isInFreeTrial: Bool {
        guard let expiryDate = Calendar.current.date(byAdding: .month, value: Self.freeTrialMonths, to: installDate) else {
            return false
        }
        return Date.now < expiryDate
    }

    var freeTrialDaysRemaining: Int {
        guard isInFreeTrial else { return 0 }
        guard let expiryDate = Calendar.current.date(byAdding: .month, value: Self.freeTrialMonths, to: installDate) else {
            return 0
        }
        let days = Calendar.current.dateComponents([.day], from: Date.now, to: expiryDate).day ?? 0
        return max(0, days)
    }

    var hasFreeGameToday: Bool {
        guard isInFreeTrial else { return false }
        resetFreeGamesIfNewDay()
        return freeGamesUsedToday < Self.freeGamesPerDay
    }

    var canStartNewGame: Bool {
        if !FeatureFlags.isStoreKitEnabled {
            return true
        }
        return hasFreeGameToday || remainingCredits > 0
    }

    var statusText: String {
        if !FeatureFlags.isStoreKitEnabled {
            return "Unlimited games"
        }
        var parts: [String] = []
        if isInFreeTrial {
            let daysLeft = freeTrialDaysRemaining
            parts.append("Free trial: \(daysLeft) day\(daysLeft == 1 ? "" : "s") left")
            if hasFreeGameToday {
                parts.append("1 free game available today")
            } else {
                parts.append("Free game used today")
            }
        } else {
            parts.append("Free trial expired")
        }
        if remainingCredits > 0 {
            parts.append("\(remainingCredits) purchased game\(remainingCredits == 1 ? "" : "s") remaining")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Init

    init() {
        // Load or set install date
        if let storedDate = UserDefaults.standard.object(forKey: Keys.installDate) as? Date {
            self.installDate = storedDate
        } else {
            let now = Date.now
            self.installDate = now
            UserDefaults.standard.set(now, forKey: Keys.installDate)
            logInfo("First launch — install date recorded", category: .purchases)
        }

        // Load persisted credits
        self.remainingCredits = UserDefaults.standard.integer(forKey: Keys.gameCredits)
        self.freeGamesUsedToday = UserDefaults.standard.integer(forKey: Keys.freeGamesUsedToday)

        // Reset free games if it's a new day
        resetFreeGamesIfNewDay()

        // Listen for unfinished transactions
        self.transactionListener = listenForTransactions()

        logDebug("GameCreditsManager initialized — credits: \(remainingCredits), freeTrial: \(isInFreeTrial)", category: .purchases)
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    private enum ProductLoadError: Error {
        case timeout
    }

    func loadProducts() async {
        isLoadingProducts = true
        productsLoadError = nil

        do {
            let loaded = try await withThrowingTaskGroup(of: [Product].self) { group in
                group.addTask {
                    try await Product.products(for: GameProduct.allProductIDs)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(10))
                    throw ProductLoadError.timeout
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
            products = loaded
            logInfo("Loaded \(loaded.count) products from StoreKit", category: .purchases)
        } catch ProductLoadError.timeout {
            productsLoadError = "Timed out loading products. Check your connection and try again."
            logWarning("Product load timed out", category: .purchases)
        } catch {
            productsLoadError = error.localizedDescription
            logError("Failed to load products: \(error.localizedDescription)", category: .purchases)
        }

        isLoadingProducts = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleSuccessfulPurchase(transaction)
                await transaction.finish()
                logInfo("Purchase successful — added \(Self.creditsPerPurchase) credits", category: .purchases)

            case .userCancelled:
                logDebug("User cancelled purchase", category: .purchases)

            case .pending:
                logInfo("Purchase pending (e.g. Ask to Buy)", category: .purchases)

            @unknown default:
                logWarning("Unknown purchase result", category: .purchases)
            }
        } catch {
            purchaseError = error.localizedDescription
            logError("Purchase failed: \(error.localizedDescription)", category: .purchases)
        }

        isPurchasing = false
    }

    // MARK: - Consume Credit

    func consumeGameCredit() {
        if !FeatureFlags.isStoreKitEnabled {
            return
        }

        // Use free game first if available
        if hasFreeGameToday {
            freeGamesUsedToday += 1
            logDebug("Used free game — \(Self.freeGamesPerDay - freeGamesUsedToday) free games remaining today", category: .purchases)
            return
        }

        // Otherwise consume a purchased credit
        if remainingCredits > 0 {
            remainingCredits -= 1
            logDebug("Used purchased credit — \(remainingCredits) credits remaining", category: .purchases)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        logInfo("Restoring purchases...", category: .purchases)
        do {
            try await AppStore.sync()
            logInfo("Restore purchases completed", category: .purchases)
        } catch {
            logError("Restore purchases failed: \(error.localizedDescription)", category: .purchases)
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Private Helpers

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { @Sendable in
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleSuccessfulPurchase(transaction)
                    await transaction.finish()
                } catch {
                    logError("Transaction verification failed: \(error.localizedDescription)", category: .purchases)
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func handleSuccessfulPurchase(_ transaction: Transaction) async {
        if transaction.productID == GameProduct.fiveGamePack {
            remainingCredits += Self.creditsPerPurchase
            logInfo("Credits updated — total: \(remainingCredits)", category: .purchases)
        }
    }

    private func resetFreeGamesIfNewDay() {
        let lastDateString = UserDefaults.standard.string(forKey: Keys.lastFreeGameDate) ?? ""
        let todayString = Self.dateString(from: Date.now)

        if lastDateString != todayString {
            // It's a new day — reset the free game counter
            freeGamesUsedToday = 0
            UserDefaults.standard.set(todayString, forKey: Keys.lastFreeGameDate)
        }
    }

    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
