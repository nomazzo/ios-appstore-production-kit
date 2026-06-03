import Foundation
import Testing
@testable import AppStoreProductionKit

struct AppStoreProductionKitTests {
    @MainActor
    @Test func purchaseManagerPurchasesAndRestoresWithMockClient() async throws {
        // StoreKit本体には触れず、差し替えクライアントで購入フローの状態更新を検証する。
        let suiteName = "AppStoreProductionKitTests.purchase"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        let productID = "com.example.productionkit.pro"
        let product = PurchaseProductInfo(
            id: productID,
            displayName: "Production Kit Pro",
            description: "Demo unlock",
            displayPrice: "$4.99"
        )
        let client = MockPurchaseClient(
            productsResponse: [product],
            purchaseResult: .success([productID]),
            entitlementProductIDs: []
        )
        let store = EntitlementStore(
            userDefaults: userDefaults,
            premiumKey: "premium",
            adsDisabledKey: "adsDisabled"
        )
        let manager = PurchaseManager(
            client: client,
            entitlementStore: store,
            productID: productID
        )

        let products = try await manager.loadProducts()
        let purchaseOutcome = try await manager.purchase()
        client.entitlementProductIDs = [productID]
        let restoreOutcome = try await manager.restorePurchases()

        #expect(products == [product])
        #expect(purchaseOutcome == .purchased)
        #expect(restoreOutcome == .restored(true))
        #expect(client.didSync)
        #expect(store.isPremiumUnlocked)
        #expect(store.areAdsDisabled)
    }

    @Test func featureGateBlocksFreeLimitAndAllowsPremium() {
        // 無料版の制限とPro解放時の解除を、営業デモの重要仕様として確認する。
        let freeGate = FeatureGate(isPremiumUnlocked: false)
        let premiumGate = FeatureGate(isPremiumUnlocked: true)

        let blocked = freeGate.limitResult(kind: .items, currentCount: 3, freeLimit: 3)
        let allowed = freeGate.limitResult(kind: .items, currentCount: 2, freeLimit: 3)
        let premium = premiumGate.limitResult(kind: .items, currentCount: 99, freeLimit: 3)

        #expect(blocked.isBlocked)
        #expect(allowed.isAllowed)
        #expect(premium.isAllowed)
        #expect(premium.limit == nil)
    }

    @Test func adConfigurationUsesTestIdsAndNonPersonalizedExtras() {
        // 公開リポジトリでは本番広告IDを使わず、テストIDとnpa設定だけを確認する。
        let config = AdConfiguration(usesTestAds: true)
        let policy = AdRequestPolicy(hasPersonalizedAdsConsent: false)

        #expect(config.adUnitID(for: .interstitial) == "ca-app-pub-3940256099942544/4411468910")
        #expect(policy.extras == ["npa": "1"])
    }

    @Test func lifecycleConsidersAppOpenAdAfterBackgroundReturn() {
        // バックグラウンド復帰時だけApp Open Adの候補にする挙動を固定乱数で検証する。
        var coordinator = AppLifecycleCoordinator(random: { 0.2 })

        let launch = coordinator.handle(.launched, adsDisabled: false)
        _ = coordinator.handle(.enteredBackground, adsDisabled: false)
        let active = coordinator.handle(.becameActive, adsDisabled: false, appOpenAdShowRate: 0.3)
        let nextActive = coordinator.handle(.becameActive, adsDisabled: false, appOpenAdShowRate: 1.0)

        #expect(launch.shouldPreloadAds)
        #expect(!launch.shouldConsiderAppOpenAd)
        #expect(active.shouldConsiderAppOpenAd)
        #expect(!nextActive.shouldConsiderAppOpenAd)
    }

    @Test func appSettingsStoreSavesLoadsAndResetsCodableSettings() throws {
        // アプリ固有の設定型でも、Codableなら同じstoreを流用できることを確認する。
        let suiteName = "AppStoreProductionKitTests.settings"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = AppSettingsStore(
            defaultValue: DemoSettings(),
            userDefaults: userDefaults,
            key: "settings"
        )

        store.save(DemoSettings(isPremiumUnlocked: true, launchCount: 7))

        #expect(store.load() == DemoSettings(isPremiumUnlocked: true, launchCount: 7))

        store.reset()

        #expect(store.load() == DemoSettings())
    }

    @Test func reviewPolicyWaitsForLaunchCountAndCooldown() throws {
        // レビュー依頼が起動回数と前回依頼日で制御されることを確認する。
        let suiteName = "AppStoreProductionKitTests.review"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        let manager = ReviewRequestManager(
            userDefaults: userDefaults,
            policy: ReviewRequestPolicy(minimumLaunchCount: 2, minimumDaysBetweenRequests: 30),
            calendar: calendar
        )
        let firstDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        let tooSoon = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 15)))
        let later = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))

        _ = manager.recordLaunch()
        #expect(!manager.shouldRequestReview(now: firstDate))

        _ = manager.recordLaunch()
        #expect(manager.shouldRequestReview(now: firstDate))

        manager.markReviewRequested(at: firstDate)
        #expect(!manager.shouldRequestReview(now: tooSoon))
        #expect(manager.shouldRequestReview(now: later))
    }
}

private struct DemoSettings: Codable, Equatable, Sendable {
    var isPremiumUnlocked = false
    var launchCount = 0
}

private final class MockPurchaseClient: PurchaseClient, @unchecked Sendable {
    // 購入結果を任意に差し替えるための、テスト専用StoreKit代替。
    var productsResponse: [PurchaseProductInfo]
    var purchaseResult: PurchaseClientResult
    var entitlementProductIDs: Set<String>
    var didSync = false

    init(
        productsResponse: [PurchaseProductInfo],
        purchaseResult: PurchaseClientResult,
        entitlementProductIDs: Set<String>
    ) {
        self.productsResponse = productsResponse
        self.purchaseResult = purchaseResult
        self.entitlementProductIDs = entitlementProductIDs
    }

    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo] {
        productsResponse.filter { productIDs.contains($0.id) }
    }

    func purchase(productID: String) async throws -> PurchaseClientResult {
        purchaseResult
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        entitlementProductIDs
    }

    func sync() async throws {
        didSync = true
    }
}
