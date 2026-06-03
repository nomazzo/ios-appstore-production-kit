import Foundation
import StoreKit

public struct PurchaseProductInfo: Equatable, Identifiable, Sendable {
    // StoreKitのProductをUIやテストで扱いやすい値型に変換する。
    public var id: String
    public var displayName: String
    public var description: String
    public var displayPrice: String

    public init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
    }
}

public enum PurchaseOutcome: Equatable, Sendable {
    // キャンセルや承認待ちは失敗扱いにせず、画面側で出し分けられるようにする。
    case purchased
    case cancelled
    case pending
    case restored(Bool)
}

public enum PurchaseError: Error, LocalizedError, Equatable {
    case productNotFound
    case productLoadFailed
    case purchaseFailed
    case verificationFailed

    public var errorDescription: String? {
        switch self {
        case .productNotFound, .productLoadFailed:
            "Could not load purchase information. Please check your connection and try again."
        case .purchaseFailed, .verificationFailed:
            "The purchase could not be completed. Please try again later."
        }
    }
}

public enum PurchaseClientResult: Equatable, Sendable {
    case success(Set<String>)
    case cancelled
    case pending
}

public protocol PurchaseClient: Sendable {
    // StoreKit依存を差し替えられるようにし、購入処理をユニットテスト可能にする。
    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo]
    func purchase(productID: String) async throws -> PurchaseClientResult
    func currentEntitlementProductIDs() async -> Set<String>
    func sync() async throws
}

public struct StoreKitPurchaseClient: PurchaseClient {
    public init() {}

    public func products(for productIDs: [String]) async throws -> [PurchaseProductInfo] {
        do {
            // App Store / StoreKit Configurationから表示名と価格を取得する。
            let products = try await Product.products(for: productIDs)
            return products
                .sorted { $0.id < $1.id }
                .map {
                    PurchaseProductInfo(
                        id: $0.id,
                        displayName: $0.displayName,
                        description: $0.description,
                        displayPrice: $0.displayPrice
                    )
                }
        } catch {
            throw PurchaseError.productLoadFailed
        }
    }

    public func purchase(productID: String) async throws -> PurchaseClientResult {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // 検証済みトランザクションだけを権利更新の対象にする。
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return .success(await currentEntitlementProductIDs())
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .pending
            }
        } catch let error as PurchaseError {
            throw error
        } catch {
            throw PurchaseError.purchaseFailed
        }
    }

    public func currentEntitlementProductIDs() async -> Set<String> {
        var productIDs = Set<String>()

        // 失効済みの購入は除外し、現在有効な権利だけを見る。
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.revocationDate == nil else {
                continue
            }
            productIDs.insert(transaction.productID)
        }

        return productIDs
    }

    public func sync() async throws {
        try await AppStore.sync()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            safe
        case .unverified:
            throw PurchaseError.verificationFailed
        }
    }
}

@MainActor
public struct PurchaseManager {
    // 画面側はPurchaseManagerだけを扱い、StoreKit本体や保存先の詳細を意識しない。
    public var client: PurchaseClient
    public var entitlementStore: EntitlementStore
    public var productID: String

    public init(
        client: PurchaseClient = StoreKitPurchaseClient(),
        entitlementStore: EntitlementStore = EntitlementStore(),
        productID: String
    ) {
        self.client = client
        self.entitlementStore = entitlementStore
        self.productID = productID
    }

    public func loadProducts() async throws -> [PurchaseProductInfo] {
        let products = try await client.products(for: [productID])
        guard !products.isEmpty else {
            throw PurchaseError.productNotFound
        }
        return products
    }

    @discardableResult
    public func refreshEntitlements() async -> Bool {
        // 起動時や復元後に、現在の購入状態をローカルの権利状態へ反映する。
        let ids = await client.currentEntitlementProductIDs()
        let isUnlocked = ids.contains(productID)
        entitlementStore.updatePremiumUnlocked(isUnlocked)
        return isUnlocked
    }

    public func purchase() async throws -> PurchaseOutcome {
        let result = try await client.purchase(productID: productID)

        // 購入成功後も、実際にEntitlementへ反映されたかを確認してから解放する。
        switch result {
        case .success(let ids):
            let isUnlocked = ids.contains(productID)
            entitlementStore.updatePremiumUnlocked(isUnlocked)
            return isUnlocked ? .purchased : .pending
        case .cancelled:
            return .cancelled
        case .pending:
            return .pending
        }
    }

    public func restorePurchases() async throws -> PurchaseOutcome {
        // App Store側と同期してから、現在有効な権利を読み直す。
        try await client.sync()
        let isUnlocked = await refreshEntitlements()
        return .restored(isUnlocked)
    }
}
