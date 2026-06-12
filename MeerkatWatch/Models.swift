import Foundation
import SwiftUI

enum TimerDuration: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case twentyFive = 25
    case fortyFive = 45
    case sixty = 60

    var id: Int { rawValue }
    var seconds: Int { rawValue * 60 }
    var title: String { "\(rawValue)分" }
}

enum BurrowLevel: Int, CaseIterable, Identifiable, Codable {
    case smallHole = 1
    case grassBed
    case lookoutTower
    case undergroundRoom
    case desertBase

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .smallHole: "小さな穴"
        case .grassBed: "草のベッド"
        case .lookoutTower: "見張り台"
        case .undergroundRoom: "地下部屋"
        case .desertBase: "豪華な砂漠基地"
        }
    }

    var requiredPoints: Int {
        switch self {
        case .smallHole: 80
        case .grassBed: 180
        case .lookoutTower: 360
        case .undergroundRoom: 620
        case .desertBase: Int.max
        }
    }

    var next: BurrowLevel? {
        BurrowLevel(rawValue: rawValue + 1)
    }

    var icon: String {
        switch self {
        case .smallHole: "circle.dotted"
        case .grassBed: "leaf.fill"
        case .lookoutTower: "binoculars.fill"
        case .undergroundRoom: "square.stack.3d.down.right.fill"
        case .desertBase: "crown.fill"
        }
    }
}

struct MeerkatFriend: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let unlockDay: Int
    let symbol: String
    let imageName: String

    static let all: [MeerkatFriend] = [
        .init(id: "normal", name: "通常ミーア", description: "最初に来る真面目な見張り係。圧は強め。", unlockDay: 1, symbol: "🦫", imageName: "FriendNormal"),
        .init(id: "child", name: "子どもミーア", description: "小さいけど声は大きい。サボりを見逃さない。", unlockDay: 3, symbol: "🌱", imageName: "FriendChild"),
        .init(id: "captain", name: "隊長ミーア", description: "砂漠の集中ルールに厳しい隊長。", unlockDay: 7, symbol: "🪖", imageName: "FriendCaptain"),
        .init(id: "sleepy", name: "眠そうなミーア", description: "眠そうでも見張り精度は高い。", unlockDay: 14, symbol: "💤", imageName: "FriendSleepy"),
        .init(id: "white", name: "伝説の白ミーア", description: "30日続いた者だけが会える白い見張り番。", unlockDay: 30, symbol: "✨", imageName: "FriendWhite")
    ]
}

struct FocusResult: Identifiable, Equatable {
    let id = UUID()
    let isSuccess: Bool
    let minutes: Int
    let points: Int
    let message: String
}

enum AppPalette {
    static let sand = Color(red: 0.95, green: 0.80, blue: 0.55)
    static let clay = Color(red: 0.82, green: 0.39, blue: 0.17)
    static let cocoa = Color(red: 0.28, green: 0.16, blue: 0.10)
    static let cactus = Color(red: 0.24, green: 0.46, blue: 0.29)
    static let sky = Color(red: 0.45, green: 0.70, blue: 0.82)
    static let cream = Color(red: 1.00, green: 0.94, blue: 0.82)
}
