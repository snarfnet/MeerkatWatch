import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct MeerkatWatchApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var adPrivacy = AdPrivacyManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(adPrivacy)
                .onAppear {
                    dataManager.applyDailyLogin()
                    adPrivacy.prepareAds()
                }
        }
    }
}

final class AdPrivacyManager: ObservableObject {
    @Published private(set) var isAdSDKReady = false

    private var didPrepare = false

    func prepareAds() {
        guard !didPrepare else { return }
        didPrepare = true

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                DispatchQueue.main.async {
                    self?.startAds()
                }
            }
        } else {
            startAds()
        }
    }

    private func startAds() {
        GADMobileAds.sharedInstance().start(completionHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.isAdSDKReady = true
            }
        })
    }
}
