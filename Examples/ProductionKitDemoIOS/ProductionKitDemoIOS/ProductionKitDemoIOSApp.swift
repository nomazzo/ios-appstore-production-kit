import SwiftUI

@main
struct ProductionKitDemoIOSApp: App {
    // iPhone Simulatorでスクリーンショットを撮るための入口。画面本体はmacOS版Demoと共有する。
    @StateObject private var model = DemoViewModel()

    var body: some Scene {
        WindowGroup {
            // AppStoreProductionKitの状態をDemoViewModelに集約し、各画面は表示と操作だけを担当する。
            DemoRootView()
                .environmentObject(model)
        }
    }
}
