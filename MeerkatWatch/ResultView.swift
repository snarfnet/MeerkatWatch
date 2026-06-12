import SwiftUI

struct ResultView: View {
    let result: FocusResult

    var body: some View {
        ZStack {
            DesertBackground()

            if result.isSuccess {
                ConfettiView()
            }

            VStack(spacing: 18) {
                MascotView(mood: result.isSuccess ? .happy : .angry)
                    .frame(height: 260)

                Text(result.isSuccess ? "見張り成功" : "見張り失敗")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(result.isSuccess ? AppPalette.cactus : AppPalette.clay)
                    .multilineTextAlignment(.center)

                Text(result.message)
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppPalette.cocoa)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    StatRow(title: "集中時間", value: "\(result.minutes)分", icon: "timer")
                    StatRow(title: "獲得ポイント", value: "\(result.points)pt", icon: "sparkles")
                }
                .padding(16)
                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))

                NavigationLink {
                    BurrowView()
                } label: {
                    Label("巣穴を見る", systemImage: "mountain.2.fill")
                        .primaryButtonStyle()
                }
            }
            .padding(20)
        }
        .navigationTitle("任務結果")
        .navigationBarTitleDisplayMode(.inline)
    }
}
