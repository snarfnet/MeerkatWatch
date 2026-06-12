import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        NavigationStack {
            ZStack {
                DesertBackground()

                List {
                    ForEach(MeerkatFriend.all) { friend in
                        FriendRow(
                            friend: friend,
                            isUnlocked: dataManager.unlockedFriendIDs.contains(friend.id),
                            isSelected: dataManager.selectedFriendID == friend.id
                        ) {
                            dataManager.selectFriend(friend)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("仲間一覧")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct FriendRow: View {
    let friend: MeerkatFriend
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isUnlocked ? AppPalette.cream : Color.black.opacity(0.28))
                        .frame(width: 64, height: 64)
                    if isUnlocked {
                        FriendImageView(friend: friend, size: 58)
                    } else {
                        Text("？")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(isUnlocked ? friend.name : "未解放")
                            .font(.headline.weight(.black))
                            .foregroundStyle(AppPalette.cocoa)
                        if isSelected {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppPalette.cactus)
                        }
                    }

                    Text(isUnlocked ? friend.description : "\(friend.unlockDay)日目のログインで仲間になる")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.cocoa.opacity(0.72))
                        .multilineTextAlignment(.leading)

                    Text("解放条件：\(friend.unlockDay)日目")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.clay)
                }

                Spacer()
            }
            .padding(12)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}
