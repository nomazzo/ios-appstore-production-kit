import Foundation

public enum AdUnit: String, CaseIterable, Sendable {
    // 広告種別ごとに設定キーを固定し、画面側へ文字列キーを散らさない。
    case appOpen
    case adaptiveBanner
    case collapsibleBanner
    case interstitial
    case rewarded

    public var configKey: String {
        switch self {
        case .appOpen:
            "appOpenAdUnitID"
        case .adaptiveBanner:
            "adaptiveBannerAdUnitID"
        case .collapsibleBanner:
            "collapsibleBannerAdUnitID"
        case .interstitial:
            "interstitialAdUnitID"
        case .rewarded:
            "rewardedAdUnitID"
        }
    }

    public var googleTestID: String {
        // 公開リポジトリには本番IDを入れず、Google公式のテスト広告IDだけを使用する。
        switch self {
        case .appOpen:
            "ca-app-pub-3940256099942544/5575463023"
        case .adaptiveBanner:
            "ca-app-pub-3940256099942544/2934735716"
        case .collapsibleBanner:
            "ca-app-pub-3940256099942544/2435281174"
        case .interstitial:
            "ca-app-pub-3940256099942544/4411468910"
        case .rewarded:
            "ca-app-pub-3940256099942544/1712485313"
        }
    }
}

public struct AdConfiguration: Sendable {
    // 本番値はアプリ側のplistやCI secretから渡す想定。Package内には保持しない。
    private let values: [String: String]
    public var usesTestAds: Bool
    public var forceHideAdsForScreenshots: Bool
    public var appOpenAdBackgroundReturnShowRate: Double

    public init(
        values: [String: String] = [:],
        usesTestAds: Bool = true,
        forceHideAdsForScreenshots: Bool = false,
        appOpenAdBackgroundReturnShowRate: Double = 0.3
    ) {
        self.values = values
        self.usesTestAds = usesTestAds
        self.forceHideAdsForScreenshots = forceHideAdsForScreenshots
        self.appOpenAdBackgroundReturnShowRate = appOpenAdBackgroundReturnShowRate
    }

    public func adUnitID(for adUnit: AdUnit) -> String {
        if usesTestAds {
            // 公開サンプルや開発中は、常に安全なテスト広告IDへ寄せる。
            return adUnit.googleTestID
        }

        // 本番値が未設定でもビルドできるよう、placeholderを返して設定漏れを見つけやすくする。
        return values[adUnit.configKey] ?? "YOUR_\(adUnit.configKey)"
    }
}

public struct AdRequestPolicy: Equatable, Sendable {
    // consentが取れていない場合は、Google Mobile Adsのnpa=1相当で非パーソナライズ広告にする。
    public var hasPersonalizedAdsConsent: Bool

    public init(hasPersonalizedAdsConsent: Bool) {
        self.hasPersonalizedAdsConsent = hasPersonalizedAdsConsent
    }

    public var extras: [String: String] {
        hasPersonalizedAdsConsent ? [:] : ["npa": "1"]
    }
}

public struct FullscreenAdCooldown: Sendable {
    // 連続表示を避け、ユーザー体験を壊さないための最小表示間隔を管理する。
    private var lastPresentationDate: Date?
    public var minimumInterval: TimeInterval

    public init(
        lastPresentationDate: Date? = nil,
        minimumInterval: TimeInterval = 45
    ) {
        self.lastPresentationDate = lastPresentationDate
        self.minimumInterval = minimumInterval
    }

    public func canPresent(now: Date = Date()) -> Bool {
        guard let lastPresentationDate else { return true }
        return now.timeIntervalSince(lastPresentationDate) >= minimumInterval
    }

    public mutating func markPresented(at date: Date = Date()) {
        lastPresentationDate = date
    }
}
