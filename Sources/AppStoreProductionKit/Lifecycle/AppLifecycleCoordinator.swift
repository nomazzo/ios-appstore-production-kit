import Foundation

public enum AppLifecycleEvent: Equatable, Sendable {
    case launched
    case becameActive
    case enteredBackground
}

public struct AppLifecycleDecision: Equatable, Sendable {
    // AppDelegateやSwiftUI App側が実行する処理を、判定結果として返す。
    public var shouldPreloadAds: Bool
    public var shouldConsiderAppOpenAd: Bool

    public init(
        shouldPreloadAds: Bool,
        shouldConsiderAppOpenAd: Bool
    ) {
        self.shouldPreloadAds = shouldPreloadAds
        self.shouldConsiderAppOpenAd = shouldConsiderAppOpenAd
    }
}

public struct AppLifecycleCoordinator: Sendable {
    // バックグラウンド復帰時だけApp Open Adの表示候補にする。
    private var shouldConsiderAppOpenAdOnNextActivation = false
    private let random: @Sendable () -> Double

    public init(random: @escaping @Sendable () -> Double = { Double.random(in: 0..<1) }) {
        // 表示率の判定をテストしやすいよう、乱数生成を差し替え可能にしている。
        self.random = random
    }

    public mutating func handle(
        _ event: AppLifecycleEvent,
        adsDisabled: Bool,
        appOpenAdShowRate: Double = 0.3
    ) -> AppLifecycleDecision {
        switch event {
        case .launched:
            // 初回起動ではApp Open Adを出さず、次回以降に備えてpreloadだけ行う。
            return AppLifecycleDecision(
                shouldPreloadAds: !adsDisabled,
                shouldConsiderAppOpenAd: false
            )
        case .enteredBackground:
            // 次にactiveへ戻ったタイミングでだけ、App Open Adの表示判定を行う。
            shouldConsiderAppOpenAdOnNextActivation = true
            return AppLifecycleDecision(
                shouldPreloadAds: false,
                shouldConsiderAppOpenAd: false
            )
        case .becameActive:
            defer { shouldConsiderAppOpenAdOnNextActivation = false }
            // 設定値が範囲外でも壊れないよう、0...1へ丸めてから表示率判定する。
            let clampedRate = min(max(appOpenAdShowRate, 0), 1)
            let shouldShow = shouldConsiderAppOpenAdOnNextActivation
                && !adsDisabled
                && random() < clampedRate

            return AppLifecycleDecision(
                shouldPreloadAds: !adsDisabled,
                shouldConsiderAppOpenAd: shouldShow
            )
        }
    }
}
