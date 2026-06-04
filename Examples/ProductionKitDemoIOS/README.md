# ProductionKitDemoIOS

iPhone Simulator でスクリーンショットを撮影するための Xcode プロジェクトです。

`Examples/ProductionKitDemo/` の SwiftUI 画面を使い、`AppStoreProductionKit` はローカル Swift Package として参照します。

## 実行方法

Xcode で以下を開いてください。

```text
Examples/ProductionKitDemoIOS/ProductionKitDemoIOS.xcodeproj
```

scheme は `ProductionKitDemoIOS` を選択し、iPhone Simulator で実行します。

## 注意点

- Bundle ID は `com.example.productionkit.demo` です。
- 本番の App ID、IAP ID、AdMob ID は含めていません。
- README 掲載用に、縦長でスクロールしない Demo 画面を撮影する想定です。
