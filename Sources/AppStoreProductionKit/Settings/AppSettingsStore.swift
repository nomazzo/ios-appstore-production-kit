import Foundation

public extension Notification.Name {
    // 設定変更を画面やWidget更新などへ伝えるための共通通知。
    static let productionKitSettingsDidChange = Notification.Name("productionKitSettingsDidChange")
}

public struct AppSettingsStore<Settings: Codable & Sendable> {
    // 設定型をgenericにし、アプリごとのAppSettingsへそのまま流用できるようにする。
    private let userDefaults: UserDefaults
    private let key: String
    private let defaultValue: Settings
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        defaultValue: Settings,
        userDefaults: UserDefaults = .standard,
        key: String = "productionKit.appSettings"
    ) {
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> Settings {
        guard let data = userDefaults.data(forKey: key) else {
            return defaultValue
        }

        // 壊れた保存データがあっても起動不能にせず、default値へ戻す。
        return (try? decoder.decode(Settings.self, from: data)) ?? defaultValue
    }

    public func save(_ settings: Settings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: key)
        // 保存後に通知し、画面側が明示的に再読込できるようにする。
        NotificationCenter.default.post(name: .productionKitSettingsDidChange, object: nil)
    }

    public func reset() {
        userDefaults.removeObject(forKey: key)
        NotificationCenter.default.post(name: .productionKitSettingsDidChange, object: nil)
    }
}
