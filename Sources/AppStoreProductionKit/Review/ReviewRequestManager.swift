import Foundation
import StoreKit

public struct ReviewRequestPolicy: Sendable {
    // レビュー依頼の頻度条件をまとめ、アプリごとに調整しやすくする。
    public var minimumLaunchCount: Int
    public var minimumDaysBetweenRequests: Int
    public var userDefaultsLaunchCountKey: String
    public var userDefaultsLastRequestDateKey: String

    public init(
        minimumLaunchCount: Int = 5,
        minimumDaysBetweenRequests: Int = 90,
        userDefaultsLaunchCountKey: String = "productionKit.review.launchCount",
        userDefaultsLastRequestDateKey: String = "productionKit.review.lastRequestDate"
    ) {
        self.minimumLaunchCount = minimumLaunchCount
        self.minimumDaysBetweenRequests = minimumDaysBetweenRequests
        self.userDefaultsLaunchCountKey = userDefaultsLaunchCountKey
        self.userDefaultsLastRequestDateKey = userDefaultsLastRequestDateKey
    }
}

public struct ReviewRequestManager {
    // 実際のSKStoreReviewController呼び出しとは分け、表示してよいタイミングだけを判定する。
    private let userDefaults: UserDefaults
    private let policy: ReviewRequestPolicy
    private let calendar: Calendar

    public init(
        userDefaults: UserDefaults = .standard,
        policy: ReviewRequestPolicy = ReviewRequestPolicy(),
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.policy = policy
        self.calendar = calendar
    }

    @discardableResult
    public func recordLaunch() -> Int {
        // 起動回数はレビュー依頼の条件として使うため、アプリ起動時に加算する。
        let count = userDefaults.integer(forKey: policy.userDefaultsLaunchCountKey) + 1
        userDefaults.set(count, forKey: policy.userDefaultsLaunchCountKey)
        return count
    }

    public func shouldRequestReview(now: Date = Date()) -> Bool {
        let launchCount = userDefaults.integer(forKey: policy.userDefaultsLaunchCountKey)
        guard launchCount >= policy.minimumLaunchCount else { return false }

        guard let lastRequestDate = userDefaults.object(forKey: policy.userDefaultsLastRequestDateKey) as? Date else {
            // まだ依頼したことがなければ、起動回数条件だけで表示可能にする。
            return true
        }

        // 短期間に何度もレビュー依頼を出さないよう、前回依頼日からの間隔を見る。
        let nextAllowedDate = calendar.date(
            byAdding: .day,
            value: policy.minimumDaysBetweenRequests,
            to: lastRequestDate
        ) ?? lastRequestDate

        return now >= nextAllowedDate
    }

    public func markReviewRequested(at date: Date = Date()) {
        userDefaults.set(date, forKey: policy.userDefaultsLastRequestDateKey)
    }
}
