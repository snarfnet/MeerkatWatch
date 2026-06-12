import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var adPrivacy: AdPrivacyManager

    var body: some View {
        VStack(spacing: 0) {
            if adPrivacy.isAdSDKReady {
                BannerAdView(adUnitID: AdUnitID.top)
                    .frame(height: 50)
            }

            TabView {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }

                BurrowView()
                    .tabItem {
                        Label("巣穴", systemImage: "mountain.2.fill")
                    }

                FriendsView()
                    .tabItem {
                        Label("仲間", systemImage: "person.3.fill")
                    }
            }
            .tint(AppPalette.clay)

            if adPrivacy.isAdSDKReady {
                BannerAdView(adUnitID: AdUnitID.bottom)
                    .frame(height: 50)
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var isBouncing = false
    @State private var showLoginFriend = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesertBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 8) {
                            Text("ミーアキャットの見張り番")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(AppPalette.cocoa)
                                .multilineTextAlignment(.center)

                            Text("スマホを置く時間を、見張り番と一緒に守ろう。")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppPalette.clay)
                        }
                        .padding(.top, 18)

                        MascotView(mood: .normal)
                            .frame(height: 240)
                            .offset(y: isBouncing ? -8 : 4)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isBouncing)

                        VStack(spacing: 12) {
                            StatRow(title: "巣穴レベル", value: "Lv\(dataManager.burrowLevel.rawValue) \(dataManager.burrowLevel.title)", icon: dataManager.burrowLevel.icon)
                            StatRow(title: "仲間", value: "\(dataManager.unlockedFriends.count)匹", icon: "person.3.fill")
                            StatRow(title: "連続ログイン", value: "\(dataManager.loginStreak)日", icon: "calendar.badge.checkmark")
                            StatRow(title: "所持ポイント", value: "\(dataManager.points)pt", icon: "sparkles")
                        }
                        .padding(16)
                        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 8))

                        NavigationLink {
                            TimerView()
                        } label: {
                            Label("見張りを始める", systemImage: "timer")
                                .primaryButtonStyle()
                        }

                        HStack(spacing: 12) {
                            NavigationLink {
                                BurrowView()
                            } label: {
                                Label("巣穴を見る", systemImage: "mountain.2.fill")
                                    .secondaryButtonStyle()
                            }

                            NavigationLink {
                                FriendsView()
                            } label: {
                                Label("仲間一覧", systemImage: "person.3.fill")
                                    .secondaryButtonStyle()
                            }
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isBouncing = true
                showLoginFriend = dataManager.latestUnlockedFriend != nil
            }
            .sheet(isPresented: $showLoginFriend, onDismiss: dataManager.clearLatestUnlockedFriend) {
                if let friend = dataManager.latestUnlockedFriend {
                    NewFriendView(friend: friend)
                        .presentationDetents([.medium])
                }
            }
        }
    }
}

private struct NewFriendView: View {
    let friend: MeerkatFriend

    var body: some View {
        ZStack {
            DesertBackground()
            VStack(spacing: 16) {
                Text("新しい仲間が来ました")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(AppPalette.cocoa)
                FriendImageView(friend: friend, size: 170)
                Text(friend.name)
                    .font(.title.bold())
                Text(friend.description)
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppPalette.cocoa.opacity(0.78))
            }
            .padding(28)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager(defaults: .standard))
        .environmentObject(AdPrivacyManager())
}
