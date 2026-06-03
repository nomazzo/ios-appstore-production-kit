import Foundation

public struct EntitlementStore {
    // 公開サンプルではUserDefaultsで軽量に保存し、実案件ではKeychain等へ差し替えやすくする。
    private let userDefaults: UserDefaults
    private let premiumKey: String
    private let adsDisabledKey: String

    public init(
        userDefaults: UserDefaults = .standard,
        premiumKey: String = "productionKit.premiumUnlocked",
        adsDisabledKey: String = "productionKit.adsDisabled"
    ) {
        self.userDefaults = userDefaults
        self.premiumKey = premiumKey
        self.adsDisabledKey = adsDisabledKey
    }

    public var isPremiumUnlocked: Bool {
        userDefaults.bool(forKey: premiumKey)
    }

    public var areAdsDisabled: Bool {
        userDefaults.bool(forKey: adsDisabledKey)
    }

    public func updatePremiumUnlocked(_ isUnlocked: Bool) {
        // Pro解放時は広告非表示も同時に反映し、画面側の判定をシンプルにする。
        userDefaults.set(isUnlocked, forKey: premiumKey)
        userDefaults.set(isUnlocked, forKey: adsDisabledKey)
    }
}
