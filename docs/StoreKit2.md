# StoreKit 2 購入フロー

StoreKit layerは、小さなprotocolを中心に構成している。

```swift
public protocol PurchaseClient {
    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo]
    func purchase(productID: String) async throws -> PurchaseClientResult
    func currentEntitlementProductIDs() async -> Set<String>
    func sync() async throws
}
```

この形にすることで、アプリ側のpurchase managerをtestしやすくしている。
本番buildでは `StoreKitPurchaseClient` を使い、testやdemoではmock clientを差し替えられるようにしている。

## 公開サンプルで示している挙動

- StoreKit 2からの商品読み込み
- verified transaction の処理
- transaction finishing
- current entitlement の更新
- `AppStore.sync()` によるrestore
- purchased / cancelled / pending の結果分岐
- `UserDefaults` へのentitlement保存

## 公開リポジトリでの注意点

`com.example.demo.pro` のようなsample product IDを使用し、実際の App Store Connect product ID はcommitしない。
