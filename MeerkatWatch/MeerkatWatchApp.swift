import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct MeerkatWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dataManager = DataManager()
    @StateObject private var adPrivacy = AdPrivacyManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if adPrivacy.didCompleteTrackingFlow {
                    ContentView()
                        .environmentObject(dataManager)
                        .environmentObject(adPrivacy)
                        .onAppear {
                            dataManager.applyDailyLogin()
                        }
                } else {
                    TrackingPermissionLaunchView {
                        await adPrivacy.requestTrackingAuthorizationFromLaunch()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                adPrivacy.preparePrivacyFlow()
            }
        }
    }
}

@MainActor
final class AdPrivacyManager: ObservableObject {
    @Published private(set) var isAdSDKReady = false
    @Published private(set) var didCompleteTrackingFlow = false

    private var didPrepare = false
    private var didRequestTracking = false

    func preparePrivacyFlow() {
        guard !didPrepare else { return }
        didPrepare = true

        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            finishPrivacyFlowAndStartAds()
            return
        }
    }

    func requestTrackingAuthorizationFromLaunch() async {
        guard !didRequestTracking else { return }
        didRequestTracking = true

        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            finishPrivacyFlowAndStartAds()
            return
        }

        try? await Task.sleep(nanoseconds: 700_000_000)
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }

        finishPrivacyFlowAndStartAds()
    }

    private func finishPrivacyFlowAndStartAds() {
        didCompleteTrackingFlow = true
        startAds()
    }

    private func startAds() {
        guard !isAdSDKReady else { return }
        GADMobileAds.sharedInstance().start(completionHandler: { [weak self] _ in
            Task { @MainActor in
                self?.isAdSDKReady = true
            }
        })
    }
}

private struct TrackingPermissionLaunchView: View {
    let requestAuthorization: () async -> Void

    var body: some View {
        ZStack {
            DesertBackground()

            VStack(spacing: 22) {
                Image("MascotMeerkat")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("広告の確認")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(AppPalette.cocoa)

                    Text("次に表示される確認で、広告の配信と効果測定に使う許可を選べます。許可しなくてもアプリはそのまま使えます。")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppPalette.cocoa.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                ProgressView()
                    .tint(AppPalette.clay)
            }
            .padding(28)
        }
        .task {
            await requestAuthorization()
        }
    }
}
