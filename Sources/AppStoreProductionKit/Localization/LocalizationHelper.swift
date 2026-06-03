import Foundation

public enum LocalizationHelper {
    public static var languageCode: String? {
        Locale.current.language.languageCode?.identifier
    }

    public static func text(
        _ key: String,
        default defaultValue: String,
        bundle: Bundle = .main,
        tableName: String? = nil
    ) -> String {
        // String Catalog / Localizable.stringsに未登録でも、公開サンプルとして読めるfallback文言を返す。
        bundle.localizedString(forKey: key, value: defaultValue, table: tableName)
    }

    public static func format(
        _ key: String,
        default defaultValue: String,
        bundle: Bundle = .main,
        tableName: String? = nil,
        locale: Locale = .current,
        _ arguments: CVarArg...
    ) -> String {
        // 日付や数値を含む文言は、現在のLocaleを使って自然な表記に寄せる。
        String(
            format: text(key, default: defaultValue, bundle: bundle, tableName: tableName),
            locale: locale,
            arguments: arguments
        )
    }
}
