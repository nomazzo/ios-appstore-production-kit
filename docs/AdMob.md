# AdMob設定パターン

公開用packageでは、Google Mobile Ads SDKへ直接依存しない構成にしている。代わりに、公開しても問題ない設定値とpolicy部分だけを含めている。

- 広告ユニット種別のmapping
- Google公式のtest ad ID
- 本番IDがない場合のplaceholder fallback
- 非パーソナライズ広告向けのrequest extras
- fullscreen広告のcooldown logic

実アプリでは、これらの値を `GoogleMobileAds` のrequestやbanner / fullscreen広告objectへ変換する薄いadapterを追加する想定。

## 使用例

```swift
let config = AdConfiguration(usesTestAds: true)
let adUnitID = config.adUnitID(for: .appOpen)

let policy = AdRequestPolicy(hasPersonalizedAdsConsent: false)
let extras = policy.extras // ["npa": "1"]
```

## GitHub公開リポジトリでの注意点

`usesTestAds` が true の場合はGoogle公式のtest IDを使い、本番値がない場合はplaceholder文字列を返す仕様になっている。
