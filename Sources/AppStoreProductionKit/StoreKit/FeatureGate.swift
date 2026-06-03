import Foundation

public enum PlanLimitKind: Equatable, Sendable {
    case items
    case custom(String)
}

public struct PlanLimitResult: Equatable, Sendable {
    public var isAllowed: Bool
    public var limit: Int?
    public var currentCount: Int
    public var kind: PlanLimitKind

    public var isBlocked: Bool {
        !isAllowed
    }

    public init(
        isAllowed: Bool,
        limit: Int?,
        currentCount: Int,
        kind: PlanLimitKind
    ) {
        self.isAllowed = isAllowed
        self.limit = limit
        self.currentCount = currentCount
        self.kind = kind
    }
}

public struct FeatureGate: Sendable {
    // 課金状態を画面ごとに直接見ず、機能制限の判定をここに集約する。
    public var isPremiumUnlocked: Bool

    public init(isPremiumUnlocked: Bool) {
        self.isPremiumUnlocked = isPremiumUnlocked
    }

    public func canUsePremiumFeature() -> Bool {
        isPremiumUnlocked
    }

    public func limitResult(
        kind: PlanLimitKind,
        currentCount: Int,
        freeLimit: Int
    ) -> PlanLimitResult {
        if isPremiumUnlocked {
            // Pro解放済みの場合、個数制限は画面側へ返さない。
            return PlanLimitResult(
                isAllowed: true,
                limit: nil,
                currentCount: currentCount,
                kind: kind
            )
        }

        // 無料版では「現在数が上限未満」のときだけ新規作成を許可する。
        return PlanLimitResult(
            isAllowed: currentCount < freeLimit,
            limit: freeLimit,
            currentCount: currentCount,
            kind: kind
        )
    }
}
