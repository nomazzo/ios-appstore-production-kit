# ProductionKitDemo

このフォルダには、スクリーンショット撮影用の SwiftUI デモアプリを含めています。

実際の StoreKit / AdMob / UMP には接続せず、`AppStoreProductionKit` の公開用コンポーネントと mock client を使って、App Store アプリ運用まわりの状態管理を確認できる構成です。

README 掲載用の撮影を前提に、縦長の iPhone 風サイズで固定表示しています。各画面はスクロールせず、1枚のスクリーンショット内に主要情報が収まるようにしています。

## 画面

- Overview: kit全体の状態、公開用設定、Feature Gate
- StoreKit: 商品読み込み、購入、復元、Entitlement 反映
- Ads: Google公式テスト広告ID、非パーソナライズ広告 request extras
- Lifecycle: App Open Ad 判定、レビュー依頼の launch count / cooldown

## Run

```bash
swift run ProductionKitDemo
```

## Screenshot

README へ掲載する場合は、以下の名前で `docs/screenshots/` に配置する想定です。

```text
01-overview.png
02-storekit-purchase.png
03-admob-consent.png
04-lifecycle-review.png
```

識別子は `com.example.*`、広告IDは Google 公式テスト広告IDだけを使用しています。
