import AppStoreProductionKit
import SwiftUI

struct DemoRootView: View {
    @State private var selectedTab: DemoTab = .overview

    init() {
        // スクリーンショット自動生成時に、起動引数で表示タブを固定できるようにする。
        _selectedTab = State(initialValue: DemoTab.launchArgumentValue())
    }

    var body: some View {
        VStack(spacing: 0) {
            selectedContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 12)

            DemoTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        #if os(macOS)
        // macOS版はREADME撮影時に横長にならないよう、iPhone風の縦長サイズで固定する。
        .frame(width: 430, height: 900)
        #else
        // iOS版は実機/Simulatorのsafe areaに合わせ、下部タブがHome Indicatorへ重ならないようにする。
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaPadding(.bottom, 10)
        #endif
        .background(DemoColors.background)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .overview:
            OverviewScreen()
        case .storeKit:
            StoreKitDemoScreen()
        case .ads:
            AdsConsentDemoScreen()
        case .lifecycle:
            LifecycleReviewDemoScreen()
        }
    }
}

private enum DemoTab: String, CaseIterable, Identifiable {
    case overview
    case storeKit
    case ads
    case lifecycle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            "Overview"
        case .storeKit:
            "StoreKit"
        case .ads:
            "Ads"
        case .lifecycle:
            "Lifecycle"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "rectangle.grid.2x2"
        case .storeKit:
            "creditcard"
        case .ads:
            "megaphone"
        case .lifecycle:
            "arrow.triangle.2.circlepath"
        }
    }

    static func launchArgumentValue() -> DemoTab {
        // `xcrun simctl launch ... -demoTab ads` のように指定して撮影画面を切り替える。
        guard let value = ProcessInfo.processInfo.value(after: "-demoTab") else {
            return .overview
        }
        return DemoTab(rawValue: value) ?? .overview
    }
}

private struct DemoTabBar: View {
    @Binding var selectedTab: DemoTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(DemoTab.allCases) { tab in
                Button {
                    // 標準TabViewはmacOSで上部タブになりやすいため、撮影用に下部タブを自前で作る。
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 17, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    .background(selectedTab == tab ? Color.blue : DemoColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

}

struct OverviewScreen: View {
    @EnvironmentObject private var model: DemoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // READMEの1枚目でkit全体の守備範囲が伝わるよう、主要モジュールを集約して見せる。
            HeaderBlock(
                title: "Production Kit",
                subtitle: "Reusable App Store app components for purchase, ads, consent, review, settings, and lifecycle.",
                systemImage: "shippingbox",
                tint: .blue
            )

            LazyVGrid(columns: DemoGrid.columns, spacing: 10) {
                StatusTile(
                    title: "Purchase",
                    value: model.purchaseStatus,
                    detail: model.isPremiumUnlocked ? "Entitlement unlocked" : "Waiting",
                    systemImage: "creditcard",
                    tint: .green
                )
                StatusTile(
                    title: "Ads",
                    value: model.usesTestAds ? "Test Mode" : "Placeholder",
                    detail: model.adsDisabled ? "Ads disabled" : "Ads enabled",
                    systemImage: "megaphone",
                    tint: .orange
                )
                StatusTile(
                    title: "Consent",
                    value: model.consentStatusText,
                    detail: model.canRequestPersonalizedAdsText,
                    systemImage: "hand.raised",
                    tint: .purple
                )
                StatusTile(
                    title: "Review",
                    value: model.reviewEligible ? "Eligible" : "Waiting",
                    detail: "\(model.launchCount) launches",
                    systemImage: "star.bubble",
                    tint: .pink
                )
            }

            DemoCard(title: "Public Configuration", systemImage: "lock.shield", tint: .indigo) {
                // 公開リポジトリに本番識別子を含めていないことを、画面上でも明示する。
                KeyValueRow(label: "Product ID", value: model.productID)
                KeyValueRow(label: "Ad IDs", value: "Google test IDs")
                KeyValueRow(label: "Bundle ID", value: "Not included")
                KeyValueRow(label: "Private settings", value: "Not included")
            }

            DemoCard(title: "Feature Gate", systemImage: "switch.2", tint: .teal) {
                let result = model.featureGate.limitResult(
                    kind: .items,
                    currentCount: 3,
                    freeLimit: 3
                )
                KeyValueRow(label: "Free limit", value: result.isBlocked ? "Blocked at 3 items" : "Allowed")
                KeyValueRow(label: "Premium", value: model.featureGate.canUsePremiumFeature() ? "Enabled" : "Disabled")
            }

            Spacer(minLength: 0)
        }
    }
}

struct StoreKitDemoScreen: View {
    @EnvironmentObject private var model: DemoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // StoreKit本体には接続せず、同じPurchaseManager APIをmockで動かして設計を見せる。
            HeaderBlock(
                title: "StoreKit 2",
                subtitle: "Mocked purchase, restore, and entitlement reflection using PurchaseManager.",
                systemImage: "creditcard",
                tint: .green
            )

            DemoCard(title: "Product", systemImage: "bag", tint: .green) {
                KeyValueRow(label: "Product ID", value: model.productID)
                KeyValueRow(label: "Name", value: model.product?.displayName ?? "-")
                KeyValueRow(label: "Price", value: model.product?.displayPrice ?? "-")
                KeyValueRow(label: "Status", value: model.purchaseStatus)
                KeyValueRow(label: "Entitlement", value: model.isPremiumUnlocked ? "Unlocked" : "Locked")
            }

            LazyVGrid(columns: DemoGrid.columns, spacing: 10) {
                // 4つの操作を1画面に収め、購入・復元・リセットの流れを撮影しやすくする。
                DemoButton(title: "Load", systemImage: "arrow.down.circle", tint: .blue) {
                    Task { await model.loadProduct() }
                }
                DemoButton(title: "Purchase", systemImage: "creditcard.fill", tint: .green) {
                    Task { await model.purchase() }
                }
                DemoButton(title: "Restore", systemImage: "arrow.clockwise", tint: .orange) {
                    Task { await model.restore() }
                }
                DemoButton(title: "Reset", systemImage: "xmark.circle", tint: .red) {
                    model.resetPurchaseState()
                }
            }

            DemoCard(title: "Design Notes", systemImage: "checklist", tint: .teal) {
                BulletRow("PurchaseClient can be replaced by a mock.")
                BulletRow("Verified transactions update entitlements.")
                BulletRow("Cancelled and pending states remain explicit.")
            }

            Spacer(minLength: 0)
        }
    }
}

struct AdsConsentDemoScreen: View {
    @EnvironmentObject private var model: DemoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // AdMob ID管理とconsent状態を同じ画面で見せ、広告実装の安全性を伝える。
            HeaderBlock(
                title: "AdMob + Consent",
                subtitle: "Public-safe test IDs and consent-aware request policy.",
                systemImage: "megaphone",
                tint: .orange
            )

            DemoCard(title: "Ad Configuration", systemImage: "slider.horizontal.3", tint: .orange) {
                // 公開用ではGoogle公式テストID、本番想定ではplaceholderを表示する。
                Toggle("Use Google test ad IDs", isOn: $model.usesTestAds)
                    .font(.subheadline.weight(.semibold))
                Divider()
                ForEach(AdUnit.allCases, id: \.rawValue) { unit in
                    KeyValueRow(label: unit.title, value: model.adConfiguration.adUnitID(for: unit))
                }
            }

            DemoCard(title: "Consent State", systemImage: "hand.raised", tint: .purple) {
                // UMP等のSDKを直接持ち込まず、kit内のConsentStateとして状態を表現する。
                Picker("Consent", selection: Binding(
                    get: { model.consentState.status },
                    set: { model.setConsentStatus($0) }
                )) {
                    Text("Required").tag(ConsentStatus.required)
                    Text("Obtained").tag(ConsentStatus.obtained)
                    Text("None").tag(ConsentStatus.notRequired)
                }
                .pickerStyle(.segmented)

                Toggle("Personalized ads consent", isOn: $model.hasPersonalizedAdsConsent)
                    .font(.subheadline.weight(.semibold))
                KeyValueRow(label: "Privacy options", value: model.consentState.privacyOptionsRequired ? "Required" : "Not required")
                KeyValueRow(label: "Request extras", value: model.adRequestPolicy.extras.description)
            }

            Spacer(minLength: 0)
        }
    }
}

struct LifecycleReviewDemoScreen: View {
    @EnvironmentObject private var model: DemoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 起動・復帰・レビュー依頼の判定をUIから分離していることを見せる画面。
            HeaderBlock(
                title: "Lifecycle + Review",
                subtitle: "App open ad decisions and review prompt cooldown separated from UI code.",
                systemImage: "arrow.triangle.2.circlepath",
                tint: .blue
            )

            DemoCard(title: "Lifecycle Decision", systemImage: "iphone.gen3", tint: .blue) {
                Toggle("Ads disabled", isOn: $model.adsDisabled)
                    .font(.subheadline.weight(.semibold))

                VStack(alignment: .leading, spacing: 6) {
                    Text("App Open Ad show rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $model.appOpenAdShowRate, in: 0...1)
                }

                KeyValueRow(label: "Show rate", value: String(format: "%.2f", model.appOpenAdShowRate))
                KeyValueRow(label: "Last event", value: model.lastLifecycleEvent)
                KeyValueRow(label: "Preload ads", value: model.lifecycleDecision.shouldPreloadAds ? "true" : "false")
                KeyValueRow(label: "App Open Ad", value: model.lifecycleDecision.shouldConsiderAppOpenAd ? "true" : "false")
            }

            LazyVGrid(columns: DemoGrid.columns, spacing: 10) {
                // 実アプリのライフサイクルイベントをボタンで再現し、判定結果を固定表示する。
                DemoButton(title: "Launch", systemImage: "play.circle", tint: .green) {
                    model.handleLifecycleEvent(.launched)
                }
                DemoButton(title: "Background", systemImage: "moon", tint: .indigo) {
                    model.handleLifecycleEvent(.enteredBackground)
                }
            }

            DemoButton(title: "Became Active", systemImage: "sun.max", tint: .orange) {
                model.handleLifecycleEvent(.becameActive)
            }

            DemoCard(title: "Review Request", systemImage: "star.bubble", tint: .pink) {
                KeyValueRow(label: "Launch count", value: "\(model.launchCount)")
                KeyValueRow(label: "Minimum", value: "3 launches")
                KeyValueRow(label: "Cooldown", value: "30 days")
                KeyValueRow(label: "Should request", value: model.reviewEligible ? "true" : "false")
            }

            LazyVGrid(columns: DemoGrid.columns, spacing: 10) {
                DemoButton(title: "Record", systemImage: "plus.circle", tint: .blue) {
                    model.recordLaunchForReview()
                }
                DemoButton(title: "Requested", systemImage: "star.fill", tint: .pink) {
                    model.markReviewRequested()
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private enum DemoGrid {
    // iPhone幅でも2列で収まり、スクロールなしのスクリーンショットを撮れるサイズにする。
    static let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
}

private enum DemoColors {
    static var background: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var cardBackground: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

private struct HeaderBlock: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 大きめのアイコンとタイトルで、READMEに並べた時にも画面の違いが分かるようにする。
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 31, weight: .bold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

private struct StatusTile: View {
    var title: String
    var value: String
    var detail: String
    var systemImage: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .padding(12)
        .background(DemoColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct DemoCard<Content: View>: View {
    var title: String
    var systemImage: String
    var tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DemoColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct KeyValueRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 102, alignment: .leading)
            Text(value)
                .font(.caption.weight(.semibold))
                // AdMobのテストIDなど長い値も、横にはみ出さず1行に収める。
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct BulletRow: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.caption.weight(.medium))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct DemoButton: View {
    var title: String
    var systemImage: String
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

private extension AdUnit {
    var title: String {
        // 画面上ではスペースを節約するため、README向けに短い表示名へ変換する。
        switch self {
        case .appOpen:
            "App Open"
        case .adaptiveBanner:
            "Banner"
        case .collapsibleBanner:
            "Collapsible"
        case .interstitial:
            "Interstitial"
        case .rewarded:
            "Rewarded"
        }
    }
}
