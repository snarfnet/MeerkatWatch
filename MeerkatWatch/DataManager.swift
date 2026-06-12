import Foundation

final class DataManager: ObservableObject {
    @Published var burrowLevel: BurrowLevel = .smallHole
    @Published var points = 0
    @Published var totalFocusMinutes = 0
    @Published var successCount = 0
    @Published var loginStreak = 0
    @Published var lastLoginDate: Date?
    @Published var unlockedFriendIDs: Set<String> = ["normal"]
    @Published var selectedFriendID = "normal"
    @Published var latestUnlockedFriend: MeerkatFriend?

    private let defaults: UserDefaults
    private let calendar = Calendar.current
    private var loginMonthID = ""

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var selectedFriend: MeerkatFriend {
        MeerkatFriend.all.first { $0.id == selectedFriendID } ?? MeerkatFriend.all[0]
    }

    var unlockedFriends: [MeerkatFriend] {
        MeerkatFriend.all.filter { unlockedFriendIDs.contains($0.id) }
    }

    func applyDailyLogin() {
        let today = Date()
        let currentMonthID = monthID(for: today)

        if loginMonthID != currentMonthID {
            resetMonthlyFriends(for: currentMonthID)
        }

        if let lastLoginDate, calendar.isDate(lastLoginDate, inSameDayAs: today) {
            return
        }

        if let lastLoginDate, let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(lastLoginDate, inSameDayAs: yesterday) {
            loginStreak += 1
        } else {
            loginStreak = 1
        }

        lastLoginDate = today
        points += 10
        unlockFriendsForCurrentStreak()
        save()
    }

    func completeFocus(minutes: Int) -> FocusResult {
        let earnedPoints = max(10, minutes * 4)
        points += earnedPoints
        totalFocusMinutes += minutes
        successCount += 1
        save()

        let messages = [
            "見張り成功！よく耐えた！",
            "今日の集中、なかなかやるじゃん！",
            "巣穴が少し立派になったぞ！"
        ]

        return FocusResult(
            isSuccess: true,
            minutes: minutes,
            points: earnedPoints,
            message: messages.randomElement() ?? "見張り成功！"
        )
    }

    func failFocus(minutes: Int) -> FocusResult {
        let comfortPoints = minutes >= 25 ? 3 : 0
        points += comfortPoints
        save()

        let messages = [
            "スマホ触ったな！",
            "見張り任務失敗！",
            "まだ砂漠では生き残れないぞ！"
        ]

        return FocusResult(
            isSuccess: false,
            minutes: minutes,
            points: comfortPoints,
            message: messages.randomElement() ?? "見張り失敗…スマホ触ったな！"
        )
    }

    func canUpgradeBurrow() -> Bool {
        burrowLevel.next != nil && points >= burrowLevel.requiredPoints
    }

    func upgradeBurrow() -> Bool {
        guard let next = burrowLevel.next, canUpgradeBurrow() else { return false }
        points -= burrowLevel.requiredPoints
        burrowLevel = next
        save()
        return true
    }

    func selectFriend(_ friend: MeerkatFriend) {
        guard unlockedFriendIDs.contains(friend.id) else { return }
        selectedFriendID = friend.id
        save()
    }

    func clearLatestUnlockedFriend() {
        latestUnlockedFriend = nil
    }

    private func unlockFriendsForCurrentStreak() {
        for friend in MeerkatFriend.all where loginStreak >= friend.unlockDay {
            if !unlockedFriendIDs.contains(friend.id) {
                unlockedFriendIDs.insert(friend.id)
                latestUnlockedFriend = friend
            }
        }
    }

    private func load() {
        let savedLevel = defaults.integer(forKey: Keys.burrowLevel)
        burrowLevel = BurrowLevel(rawValue: max(savedLevel, 1)) ?? .smallHole
        points = defaults.integer(forKey: Keys.points)
        totalFocusMinutes = defaults.integer(forKey: Keys.totalFocusMinutes)
        successCount = defaults.integer(forKey: Keys.successCount)
        loginStreak = defaults.integer(forKey: Keys.loginStreak)
        lastLoginDate = defaults.object(forKey: Keys.lastLoginDate) as? Date
        loginMonthID = defaults.string(forKey: Keys.loginMonthID) ?? monthID(for: lastLoginDate ?? Date())

        if let savedIDs = defaults.stringArray(forKey: Keys.unlockedFriendIDs), !savedIDs.isEmpty {
            unlockedFriendIDs = Set(savedIDs)
        }

        selectedFriendID = defaults.string(forKey: Keys.selectedFriendID) ?? "normal"
        if !unlockedFriendIDs.contains(selectedFriendID) {
            selectedFriendID = "normal"
        }
    }

    private func save() {
        defaults.set(burrowLevel.rawValue, forKey: Keys.burrowLevel)
        defaults.set(points, forKey: Keys.points)
        defaults.set(totalFocusMinutes, forKey: Keys.totalFocusMinutes)
        defaults.set(successCount, forKey: Keys.successCount)
        defaults.set(loginStreak, forKey: Keys.loginStreak)
        defaults.set(lastLoginDate, forKey: Keys.lastLoginDate)
        defaults.set(loginMonthID, forKey: Keys.loginMonthID)
        defaults.set(Array(unlockedFriendIDs), forKey: Keys.unlockedFriendIDs)
        defaults.set(selectedFriendID, forKey: Keys.selectedFriendID)
    }

    private func resetMonthlyFriends(for monthID: String) {
        loginMonthID = monthID
        loginStreak = 0
        unlockedFriendIDs = ["normal"]
        selectedFriendID = "normal"
        latestUnlockedFriend = nil
        lastLoginDate = nil
        save()
    }

    private func monthID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return "\(year)-\(month)"
    }

    private enum Keys {
        static let burrowLevel = "burrowLevel"
        static let points = "points"
        static let totalFocusMinutes = "totalFocusMinutes"
        static let successCount = "successCount"
        static let loginStreak = "loginStreak"
        static let lastLoginDate = "lastLoginDate"
        static let loginMonthID = "loginMonthID"
        static let unlockedFriendIDs = "unlockedFriendIDs"
        static let selectedFriendID = "selectedFriendID"
    }
}
