import SwiftUI

enum MascotMood {
    case normal
    case watching
    case happy
    case angry
}

struct DesertBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                AppPalette.sky.opacity(0.70),
                AppPalette.cream,
                AppPalette.sand,
                Color(red: 0.65, green: 0.34, blue: 0.19)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            UnevenRoundedRectangle(topLeadingRadius: 120, topTrailingRadius: 90)
                .fill(AppPalette.clay.opacity(0.24))
                .frame(height: 160)
                .offset(y: 70)
                .ignoresSafeArea()
        }
    }
}

struct MascotView: View {
    @EnvironmentObject private var dataManager: DataManager
    let mood: MascotMood
    @State private var lookLeft = false
    @State private var shake = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(dataManager.selectedFriend.imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: AppPalette.cocoa.opacity(0.25), radius: 18, y: 10)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(mood == .happy ? 1.06 : 1.0)
                .offset(x: mood == .angry && shake ? -7 : 0)
                .animation(animation, value: lookLeft)
                .animation(.spring(response: 0.18, dampingFraction: 0.38).repeatCount(mood == .angry ? 6 : 0), value: shake)

            if mood == .angry {
                Text("💢")
                    .font(.system(size: 42))
                    .offset(x: -16, y: 10)
            }

            if mood == .happy {
                Text("✨")
                    .font(.system(size: 46))
                    .offset(x: -10, y: 4)
            }
        }
        .onAppear {
            lookLeft = true
            shake = true
        }
    }

    private var rotation: Double {
        switch mood {
        case .watching: lookLeft ? 5 : -5
        case .angry: shake ? 4 : -4
        case .happy: lookLeft ? 3 : -3
        case .normal: 0
        }
    }

    private var animation: Animation {
        switch mood {
        case .watching: .easeInOut(duration: 0.85).repeatForever(autoreverses: true)
        case .happy: .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
        default: .default
        }
    }
}

struct FriendImageView: View {
    let friend: MeerkatFriend
    let size: CGFloat

    var body: some View {
        Image(friend.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: AppPalette.cocoa.opacity(0.18), radius: 8, y: 4)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppPalette.clay)
                .frame(width: 26)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.cocoa.opacity(0.70))
            Spacer()
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(AppPalette.cocoa)
                .minimumScaleFactor(0.75)
        }
    }
}

struct ConfettiView: View {
    let colors: [Color] = [AppPalette.clay, AppPalette.cactus, .yellow, .white, .orange]

    var body: some View {
        TimelineView(.animation) { (timeline: TimelineViewDefaultContext) in
            Canvas { (context: inout GraphicsContext, size: CGSize) in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<48 {
                    let x = (Double(index * 53).truncatingRemainder(dividingBy: size.width + 80)) - 40
                    let speed = Double(70 + (index % 7) * 24)
                    let y = (time * speed + Double(index * 31)).truncatingRemainder(dividingBy: size.height + 120) - 60
                    let rect = CGRect(x: x, y: y, width: Double(8 + index % 5), height: Double(16 + index % 9))
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(colors[index % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        self
            .font(.title3.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(AppPalette.clay, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: AppPalette.clay.opacity(0.35), radius: 12, y: 6)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.subheadline.weight(.black))
            .foregroundStyle(AppPalette.cocoa)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppPalette.clay.opacity(0.18), lineWidth: 1)
            )
    }
}
