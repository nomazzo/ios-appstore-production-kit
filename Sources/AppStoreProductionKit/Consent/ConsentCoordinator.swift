import Foundation

public enum ConsentStatus: Equatable, Sendable {
    // UMPなどのSDK固有型をそのまま公開せず、アプリ内で扱いやすい状態に丸める。
    case unknown
    case required
    case obtained
    case notRequired
}

public struct ConsentState: Equatable, Sendable {
    public var status: ConsentStatus
    public var privacyOptionsRequired: Bool

    public var canRequestPersonalizedAds: Bool {
        // 同意取得済み、または同意不要の地域ではパーソナライズ広告を許可できる。
        status == .obtained || status == .notRequired
    }

    public init(
        status: ConsentStatus = .unknown,
        privacyOptionsRequired: Bool = false
    ) {
        self.status = status
        self.privacyOptionsRequired = privacyOptionsRequired
    }
}

public protocol ConsentClient: Sendable {
    // 実アプリではGoogle UMPなどをこのprotocolへ適合させる。
    func requestConsentInfoUpdate() async throws -> ConsentState
    func presentConsentFormIfNeeded() async throws -> ConsentState
    func presentPrivacyOptions() async throws -> ConsentState
}

public actor ConsentCoordinator {
    // consent状態は起動直後や設定画面から更新されるため、actorで順序を保つ。
    private let client: ConsentClient
    private var state: ConsentState

    public init(
        client: ConsentClient,
        initialState: ConsentState = ConsentState()
    ) {
        self.client = client
        self.state = initialState
    }

    public func currentState() -> ConsentState {
        state
    }

    @discardableResult
    public func refresh() async throws -> ConsentState {
        // 起動時に最新のconsent requirementを取得する。
        state = try await client.requestConsentInfoUpdate()
        return state
    }

    @discardableResult
    public func presentFormIfNeeded() async throws -> ConsentState {
        // 必要な地域だけフォームを表示し、結果を内部状態に反映する。
        state = try await client.presentConsentFormIfNeeded()
        return state
    }

    @discardableResult
    public func presentPrivacyOptions() async throws -> ConsentState {
        state = try await client.presentPrivacyOptions()
        return state
    }
}
