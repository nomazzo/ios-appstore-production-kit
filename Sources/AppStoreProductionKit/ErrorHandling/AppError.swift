import Foundation

public struct AppError: Error, LocalizedError, Equatable, Sendable {
    // 画面表示用の文言と、ログやテストで追いやすいcodeを分けて持つ。
    public var code: String
    public var message: String
    public var recoverySuggestion: String?

    public init(
        code: String,
        message: String,
        recoverySuggestion: String? = nil
    ) {
        self.code = code
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }

    public var errorDescription: String? {
        message
    }

    public var failureReason: String? {
        code
    }
}
