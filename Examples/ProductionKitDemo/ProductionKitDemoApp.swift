import SwiftUI

@main
struct ProductionKitDemoApp: App {
    @StateObject private var model = DemoViewModel()

    var body: some Scene {
        WindowGroup {
            DemoRootView()
                .environmentObject(model)
        }
        #if os(macOS)
        .defaultSize(width: 430, height: 900)
        .windowResizability(.contentSize)
        #endif
    }
}
