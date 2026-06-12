import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var dataManager: DataManager
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Text(isRunning ? "見張り中です" : "集中時間を選んでください")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(AppPalette.cocoa)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 8))

                    MascotView(mood: isRunning ? .watching : .normal)
                        .frame(height: 205)

                    Text(timeText)
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppPalette.cocoa)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.vertical, 4)

                    if !isRunning {
                        durationPicker
                    } else {
                        Text("見張り番が見ています。\nこの画面から離れないでください。")
                            .font(.title3.weight(.black))
                            .foregroundStyle(AppPalette.clay)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
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
                .padding(.bottom, 28)
            }
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
