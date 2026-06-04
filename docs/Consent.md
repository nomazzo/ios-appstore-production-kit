# 同意管理

同意取得のflowはSDKや対象地域によって変わるため、このpackageではvendor SDKへ直接依存せず、小さな抽象化だけを公開している。

```swift
public protocol ConsentClient {
    func requestConsentInfoUpdate() async throws -> ConsentState
    func presentConsentFormIfNeeded() async throws -> ConsentState
    func presentPrivacyOptions() async throws -> ConsentState
}
```

実アプリでは、`ConsentClient` adapterが Google UMP などのconsent providerを包む。
package側の `ConsentCoordinator` は状態管理と呼び出し順序の制御を担当する。

## 公開サンプルで示している挙動

- unknown / required / obtained / not-required の状態管理
- privacy options の表示可否
- personalized ad の利用可否
- async flow の順序制御

## 公開リポジトリでの注意点

test device identifier、privateなdebug設定、アプリ固有の同意画面スクリーンショットはcommitしない。
