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
        case .undergroundRoom: "地下ルーム"
        case .desertBase: "立派な砂漠基地"
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
        .init(id: "normal", name: "まじめミーア", description: "最初に来てくれる、正面顔の見張り係。姿勢がいいです。", unlockDay: 1, symbol: "M", imageName: "FriendNormal"),
        .init(id: "child", name: "こどもミーア", description: "小さいけれど声は大きめ。さぼりを見逃しません。", unlockDay: 3, symbol: "C", imageName: "FriendChild"),
        .init(id: "captain", name: "隊長ミーア", description: "砂漠の集中ルールに厳しい隊長です。", unlockDay: 7, symbol: "K", imageName: "FriendCaptain"),
        .init(id: "sleepy", name: "ねむそうミーア", description: "眠そうでも見張り精度は高めです。", unlockDay: 14, symbol: "Z", imageName: "FriendSleepy"),
        .init(id: "white", name: "伝説の白ミーア", description: "30日続いた人だけが会える白い見張り番です。", unlockDay: 30, symbol: "W", imageName: "FriendWhite")
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
