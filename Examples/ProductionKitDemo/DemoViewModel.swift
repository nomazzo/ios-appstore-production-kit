import AppStoreProductionKit
import Foundation

@MainActor
final class DemoViewModel: ObservableObject {
    let productID = "com.example.productionkit.pro"

    @Published var product: PurchaseProductInfo?
    @Published var purchaseStatus = "Ready"
    @Published var isPremiumUnlocked = false

    @Published var usesTestAds = true
    @Published var hasPersonalizedAdsConsent = false

    @Published var consentState = ConsentState(status: .required, privacyOptionsRequired: true)

    @Published var adsDisabled = false
    @Published var appOpenAdShowRate = 0.3
    @Published var lifecycleDecision = AppLifecycleDecision(
        shouldPreloadAds: false,
        shouldConsiderAppOpenAd: false
    )
    @Published var lastLifecycleEvent = "None"

    @Published var launchCount = 0
    @Published var reviewEligible = false
    @Published var lastReviewRequestText = "Never"

    private let userDefaults: UserDefaults
    private let purchaseClient: DemoPurchaseClient
    private let entitlementStore: EntitlementStore
    private var lifecycleCoordinator = AppLifecycleCoordinator(random: { 0.2 })

    init() {
        // Demo専用のsuiteを使い、ユーザーの標準UserDefaultsを汚さないようにする。
        let suiteName = "ProductionKitDemo"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.userDefaults = defaults

        let demoProduct = PurchaseProductInfo(
            // 公開用なので、実IAP IDではなくcom.example配下のサンプル商品IDを使う。
            id: productID,
            displayName: "Production Kit Pro",
            description: "Demo unlock for premium app features",
            displayPrice: "$4.99"
        )
        self.product = demoProduct
        self.purchaseClient = DemoPurchaseClient(
            productsResponse: [demoProduct],
            purchaseResult: .success([productID]),
            entitlementProductIDs: []
        )
        self.entitlementStore = EntitlementStore(
            userDefaults: defaults,
            premiumKey: "demo.premiumUnlocked",
            adsDisabledKey: "demo.adsDisabled"
        )

        // 起動時に保存済みの権利状態を読み、Overviewへ反映する。
        self.isPremiumUnlocked = entitlementStore.isPremiumUnlocked
        self.adsDisabled = entitlementStore.areAdsDisabled
        refreshReviewState()
        applyLaunchScenarioIfNeeded()
    }

    var purchaseManager: PurchaseManager {
        // 画面側はPurchaseManagerだけを使い、StoreKit本体かmockかを意識しない。
        PurchaseManager(
            client: purchaseClient,
            entitlementStore: entitlementStore,
            productID: productID
        )
    }

    var featureGate: FeatureGate {
        FeatureGate(isPremiumUnlocked: isPremiumUnlocked)
    }

    var adConfiguration: AdConfiguration {
        // 本番IDは持たず、テストIDまたはplaceholderだけを画面に出す。
        AdConfiguration(
            values: [
                "appOpenAdUnitID": "YOUR_appOpenAdUnitID",
                "adaptiveBannerAdUnitID": "YOUR_adaptiveBannerAdUnitID",
                "collapsibleBannerAdUnitID": "YOUR_collapsibleBannerAdUnitID",
                "interstitialAdUnitID": "YOUR_interstitialAdUnitID",
                "rewardedAdUnitID": "YOUR_rewardedAdUnitID"
            ],
            usesTestAds: usesTestAds,
            appOpenAdBackgroundReturnShowRate: appOpenAdShowRate
        )
    }

    var adRequestPolicy: AdRequestPolicy {
        AdRequestPolicy(hasPersonalizedAdsConsent: hasPersonalizedAdsConsent)
    }

    var consentStatusText: String {
        consentState.status.displayName
    }

    var canRequestPersonalizedAdsText: String {
        consentState.canRequestPersonalizedAds ? "Allowed" : "Not allowed"
    }

    var reviewManager: ReviewRequestManager {
        // 撮影しやすいよう、Demoではレビュー依頼条件を3起動・30日に短く設定する。
        ReviewRequestManager(
            userDefaults: userDefaults,
            policy: ReviewRequestPolicy(
                minimumLaunchCount: 3,
                minimumDaysBetweenRequests: 30,
                userDefaultsLaunchCountKey: "demo.review.launchCount",
                userDefaultsLastRequestDateKey: "demo.review.lastRequestDate"
            )
        )
    }

    func loadProduct() async {
        do {
            // StoreKit本体ではなくmock clientを通して、商品取得の流れだけを見せる。
            product = try await purchaseManager.loadProducts().first
            purchaseStatus = "Product loaded"
        } catch {
            purchaseStatus = error.localizedDescription
        }
    }

    func purchase() async {
        do {
            // mock clientの購入結果を通し、EntitlementStoreへ反映される流れを確認する。
            let outcome = try await purchaseManager.purchase()
            applyPurchaseOutcome(outcome)
        } catch {
            purchaseStatus = error.localizedDescription
        }
    }

    func restore() async {
        do {
            // 復元デモでは、App Store同期後にEntitlementが見つかった状態をmockで再現する。
            purchaseClient.entitlementProductIDs = [productID]
            let outcome = try await purchaseManager.restorePurchases()
            applyPurchaseOutcome(outcome)
        } catch {
            purchaseStatus = error.localizedDescription
        }
    }

    func resetPurchaseState() {
        purchaseClient.entitlementProductIDs = []
        entitlementStore.updatePremiumUnlocked(false)
        isPremiumUnlocked = false
        adsDisabled = false
        purchaseStatus = "Ready"
    }

    func setConsentStatus(_ status: ConsentStatus) {
        // consent状態を変えたら、広告リクエスト方針も同じタイミングで更新する。
        consentState = ConsentState(
            status: status,
            privacyOptionsRequired: status == .required || status == .obtained
        )
        hasPersonalizedAdsConsent = consentState.canRequestPersonalizedAds
    }

    func handleLifecycleEvent(_ event: AppLifecycleEvent) {
        // 実際のAppDelegate/ScenePhaseの代わりに、ボタン操作でライフサイクル判定を再現する。
        lastLifecycleEvent = event.displayName
        lifecycleDecision = lifecycleCoordinator.handle(
            event,
            adsDisabled: adsDisabled,
            appOpenAdShowRate: appOpenAdShowRate
        )
    }

    func recordLaunchForReview() {
        launchCount = reviewManager.recordLaunch()
        refreshReviewState()
    }

    func markReviewRequested() {
        reviewManager.markReviewRequested()
        lastReviewRequestText = "Just now"
        refreshReviewState()
    }

    func resetReviewState() {
        userDefaults.removeObject(forKey: "demo.review.launchCount")
        userDefaults.removeObject(forKey: "demo.review.lastRequestDate")
        lastReviewRequestText = "Never"
        refreshReviewState()
    }

    private func applyPurchaseOutcome(_ outcome: PurchaseOutcome) {
        // 画面表示用の短いステータスに変換し、Overviewにも反映する。
        switch outcome {
        case .purchased:
            purchaseStatus = "Purchased"
        case .cancelled:
            purchaseStatus = "Cancelled"
        case .pending:
            purchaseStatus = "Pending"
        case .restored(let restored):
            purchaseStatus = restored ? "Restored" : "No purchase found"
        }

        isPremiumUnlocked = entitlementStore.isPremiumUnlocked
        adsDisabled = entitlementStore.areAdsDisabled
    }

    private func refreshReviewState() {
        launchCount = userDefaults.integer(forKey: "demo.review.launchCount")
        reviewEligible = reviewManager.shouldRequestReview()
    }

    private func applyLaunchScenarioIfNeeded() {
        guard let scenario = ProcessInfo.processInfo.value(after: "-demoScenario") else { return }

        // スクリーンショット撮影時は保存状態の影響を避け、毎回同じ状態から始める。
        resetPurchaseState()
        resetReviewState()
        usesTestAds = true
        hasPersonalizedAdsConsent = false
        consentState = ConsentState(status: .required, privacyOptionsRequired: true)
        lifecycleCoordinator = AppLifecycleCoordinator(random: { 0.2 })
        lifecycleDecision = AppLifecycleDecision(shouldPreloadAds: false, shouldConsiderAppOpenAd: false)
        lastLifecycleEvent = "None"
        appOpenAdShowRate = 0.3

        switch scenario {
        case "purchased":
            // README掲載用の購入済みStoreKit画面を作る。
            purchaseClient.entitlementProductIDs = [productID]
            entitlementStore.updatePremiumUnlocked(true)
            isPremiumUnlocked = true
            adsDisabled = true
            purchaseStatus = "Purchased"
        case "restored":
            // 追加スクリーンショット用に、復元済み状態を直接再現する。
            purchaseClient.entitlementProductIDs = [productID]
            entitlementStore.updatePremiumUnlocked(true)
            isPremiumUnlocked = true
            adsDisabled = true
            purchaseStatus = "Restored"
        case "consentRequired":
            setConsentStatus(.required)
        case "consentObtained":
            setConsentStatus(.obtained)
        case "productionAds":
            // 本番IDを入れないまま、placeholder表示で公開安全性を確認する。
            usesTestAds = false
            setConsentStatus(.notRequired)
        case "lifecycleActive":
            // App Open Adの判定がtrueになる流れを、起動引数だけで再現する。
            handleLifecycleEvent(.launched)
            handleLifecycleEvent(.enteredBackground)
            handleLifecycleEvent(.becameActive)
        case "reviewEligible":
            // レビュー依頼可能状態を、手動タップなしで撮影できるようにする。
            userDefaults.set(3, forKey: "demo.review.launchCount")
            lastReviewRequestText = "Never"
            refreshReviewState()
        default:
            break
        }
    }
}

extension ProcessInfo {
    func value(after flag: String) -> String? {
        // `-demoScenario purchased` のような起動引数から、次の値だけを取り出す。
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let nextIndex = arguments.index(after: index)
        guard arguments.indices.contains(nextIndex) else { return nil }
        return arguments[nextIndex]
    }
}

extension ConsentStatus {
    var displayName: String {
        switch self {
        case .unknown:
            "Unknown"
        case .required:
            "Required"
        case .obtained:
            "Obtained"
        case .notRequired:
            "Not Required"
        }
    }
}

extension AppLifecycleEvent {
    var displayName: String {
        switch self {
        case .launched:
            "Launched"
        case .becameActive:
            "Became Active"
        case .enteredBackground:
            "Entered Background"
        }
    }
}

private final class DemoPurchaseClient: PurchaseClient, @unchecked Sendable {
    // Demo画面から購入結果を再現するための、StoreKit 2の代替クライアント。
    var productsResponse: [PurchaseProductInfo]
    var purchaseResult: PurchaseClientResult
    var entitlementProductIDs: Set<String>

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

    func sync() async throws {}
}
