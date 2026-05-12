import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedDuration: TimerDuration = .twentyFive
    @State private var remainingSeconds = TimerDuration.twentyFive.seconds
    @State private var isRunning = false
    @State private var result: FocusResult?
    @State private var showResult = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DesertBackground()

            VStack(spacing: 18) {
                Text(isRunning ? "周囲を見張り中" : "集中時間を選べ")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppPalette.cocoa)

                MascotView(mood: isRunning ? .watching : .normal)
                    .frame(height: 230)

                Text(timeText)
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppPalette.cocoa)
                    .padding(.vertical, 8)

                if !isRunning {
                    durationPicker
                } else {
                    Text("おい、今見張り中だぞ！画面から離れるな。")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppPalette.clay)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    isRunning ? failAndShowResult() : start()
                } label: {
                    Label(isRunning ? "中断する" : "開始", systemImage: isRunning ? "xmark.octagon.fill" : "play.fill")
                        .primaryButtonStyle()
                }
                .background(isRunning ? Color.red.opacity(0.2) : Color.clear)

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .navigationTitle("見張りタイマー")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isRunning)
        .onReceive(timer) { _ in
            tick()
        }
        .onChange(of: selectedDuration) { _, newValue in
            if !isRunning {
                remainingSeconds = newValue.seconds
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if isRunning && newPhase != .active {
                failAndShowResult()
            }
        }
        .onDisappear {
            if isRunning {
                failAndShowResult()
            }
        }
        .navigationDestination(isPresented: $showResult) {
            if let result {
                ResultView(result: result)
            }
        }
    }

    private var durationPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 10)], spacing: 10) {
            ForEach(TimerDuration.allCases) { duration in
                Button {
                    selectedDuration = duration
                } label: {
                    Text(duration.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(selectedDuration == duration ? .white : AppPalette.cocoa)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            selectedDuration == duration ? AppPalette.clay : .white.opacity(0.74),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
    }

    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func start() {
        remainingSeconds = selectedDuration.seconds
        isRunning = true
    }

    private func tick() {
        guard isRunning else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            isRunning = false
            result = dataManager.completeFocus(minutes: selectedDuration.rawValue)
            showResult = true
        }
    }

    private func failAndShowResult() {
        guard isRunning else { return }
        isRunning = false
        result = dataManager.failFocus(minutes: selectedDuration.rawValue)
        showResult = true
    }
}
