import SwiftUI

struct BurrowView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var didLevelUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesertBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        burrowIllustration

                        VStack(spacing: 12) {
                            StatRow(title: "現在の巣穴", value: "Lv\(dataManager.burrowLevel.rawValue) \(dataManager.burrowLevel.title)", icon: dataManager.burrowLevel.icon)
                            StatRow(title: "所持ポイント", value: "\(dataManager.points)pt", icon: "sparkles")
                            StatRow(title: "成功回数", value: "\(dataManager.successCount)回", icon: "checkmark.seal.fill")
                            StatRow(title: "合計集中時間", value: "\(dataManager.totalFocusMinutes)分", icon: "clock.fill")
                        }
                        .padding(16)
                        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))

                        nextLevelPanel

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                didLevelUp = dataManager.upgradeBurrow()
                            }
                        } label: {
                            Label(dataManager.burrowLevel.next == nil ? "最大レベル" : "巣穴を強化", systemImage: "hammer.fill")
                                .primaryButtonStyle()
                        }
                        .disabled(!dataManager.canUpgradeBurrow())
                        .opacity(dataManager.canUpgradeBurrow() ? 1 : 0.55)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("巣穴")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var burrowIllustration: some View {
        ZStack {
            Image("BurrowRealistic")
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipped()

            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .clear,
                    .black.opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    Image(systemName: dataManager.burrowLevel.icon)
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 66)
                        .background(AppPalette.cocoa.opacity(0.72), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.72), lineWidth: 1)
                        )
                    Spacer()
                }

                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現在の巣穴")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white.opacity(0.84))

                        Text(dataManager.burrowLevel.title)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Spacer()
                }
            }
            .padding(18)

            if didLevelUp {
                Circle()
                    .stroke(.yellow.opacity(0.85), lineWidth: 10)
                    .frame(width: 230, height: 230)
                    .blur(radius: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: AppPalette.cocoa.opacity(0.18), radius: 14, y: 8)
    }

    private var nextLevelPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let next = dataManager.burrowLevel.next {
                Text("次のレベル")
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppPalette.clay)
                Text("Lv\(next.rawValue) \(next.title)")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppPalette.cocoa)
                ProgressView(value: min(Double(dataManager.points), Double(dataManager.burrowLevel.requiredPoints)), total: Double(dataManager.burrowLevel.requiredPoints))
                    .tint(AppPalette.cactus)
                Text("あと \(max(0, dataManager.burrowLevel.requiredPoints - dataManager.points))pt")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.cocoa.opacity(0.72))
            } else {
                Text("立派な砂漠基地が完成しました。")
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppPalette.cocoa)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }
}
