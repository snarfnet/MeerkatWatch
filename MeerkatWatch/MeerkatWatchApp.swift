import SwiftUI

@main
struct MeerkatWatchApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onAppear {
                    dataManager.applyDailyLogin()
                }
        }
    }
}
