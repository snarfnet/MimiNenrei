import SwiftUI

struct ContentView: View {
    @State private var screen: Screen = .home

    enum Screen {
        case home
        case prepare
        case test
        case result
    }

    @State private var test = HearingTest()
    @State private var sound = SoundGenerator()

    var body: some View {
        ZStack {
            Colors.bg.ignoresSafeArea()

            switch screen {
            case .home:
                HomeView(onStart: { screen = .prepare })
            case .prepare:
                PrepareView(onReady: {
                    test.reset()
                    screen = .test
                })
            case .test:
                TestView(test: test, sound: sound, onFinish: {
                    sound.stop()
                    screen = .result
                })
            case .result:
                ResultView(test: test, onRetry: {
                    test.reset()
                    screen = .home
                })
            }
        }
    }
}

// MARK: - Home

private struct HomeView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "ear")
                .font(.system(size: 80))
                .foregroundStyle(Colors.accent)

            Text("みみ年齢")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(Colors.text)

            Text("あなたの耳は何歳？\n高い音がどこまで聞こえるかテストします")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Colors.sub)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)

            Spacer()

            BigButton(title: "テスト開始", icon: "play.fill") {
                onStart()
            }

            Text("※ イヤホン推奨・静かな場所で")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Colors.sub)

            Spacer().frame(height: 40)
        }
    }
}

// MARK: - Prepare

private struct PrepareView: View {
    let onReady: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 64))
                .foregroundStyle(Colors.accent)

            Text("準備")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(Colors.text)

            VStack(alignment: .leading, spacing: 16) {
                PrepareRow(num: "1", text: "イヤホンかヘッドホンを装着")
                PrepareRow(num: "2", text: "音量を中くらいに設定")
                PrepareRow(num: "3", text: "静かな場所で実施")
            }
            .padding(24)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
            .padding(.horizontal, 24)

            Spacer()

            BigButton(title: "準備できた", icon: "checkmark") {
                onReady()
            }

            Spacer().frame(height: 40)
        }
    }
}

private struct PrepareRow: View {
    let num: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text(num)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Colors.accent, in: Circle())

            Text(text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Colors.text)
        }
    }
}

// MARK: - Test

private struct TestView: View {
    @Bindable var test: HearingTest
    @Bindable var sound: SoundGenerator
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            Text("テスト中")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Colors.text)

            // Progress
            ProgressView(value: test.progress)
                .tint(Colors.accent)
                .scaleEffect(y: 2.5)
                .padding(.horizontal, 40)

            Text("\(test.currentIndex + 1) / \(test.steps.count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Colors.sub)

            Spacer()

            if let step = test.currentStep {
                VStack(spacing: 16) {
                    Text(step.label)
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundStyle(Colors.accent)

                    // Play button
                    Button {
                        sound.play(frequency: step.frequency, duration: 2.5)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: sound.isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                                .font(.system(size: 28))
                            Text(sound.isPlaying ? "再生中..." : "音を鳴らす")
                                .font(.system(size: 24, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(sound.isPlaying ? Color.orange : Colors.accent, in: RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 40)
                    }
                }

                Spacer()

                Text("音は聞こえましたか？")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Colors.text)

                HStack(spacing: 20) {
                    AnswerButton(title: "聞こえた", icon: "checkmark.circle.fill", color: .green) {
                        sound.stop()
                        test.answer(heard: true)
                        if test.isFinished { onFinish() }
                    }

                    AnswerButton(title: "聞こえない", icon: "xmark.circle.fill", color: .red) {
                        sound.stop()
                        test.answer(heard: false)
                        if test.isFinished { onFinish() }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer().frame(height: 40)
        }
    }
}

private struct AnswerButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                Text(title)
                    .font(.system(size: 20, weight: .black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(color.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Result

private struct ResultView: View {
    let test: HearingTest
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Text("結果")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Colors.text)

                // Ear age circle
                ZStack {
                    Circle()
                        .stroke(Colors.accent.opacity(0.2), lineWidth: 12)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: min(1.0, Double(80 - test.earAge) / 80.0))
                        .stroke(Colors.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("耳年齢")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Colors.sub)
                        Text("\(test.earAge)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(Colors.accent)
                        Text("歳")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Colors.sub)
                    }
                }

                Text(test.ageComment)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Colors.text)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)

                // Detail card
                VStack(alignment: .leading, spacing: 14) {
                    Text("テスト詳細")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Colors.sub)

                    ForEach(Array(test.steps.enumerated()), id: \.element.id) { i, step in
                        HStack {
                            Text(step.label)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Colors.text)
                            Spacer()
                            Text(step.ageRange)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Colors.sub)
                            if i < test.results.count {
                                Image(systemName: test.results[i] ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(test.results[i] ? .green : .red)
                                    .font(.system(size: 20))
                            }
                        }
                        if i < test.steps.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                .padding(.horizontal, 24)

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("耳を守るヒント")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Colors.sub)

                    TipRow(icon: "speaker.slash", text: "大きな音を長時間聴かない")
                    TipRow(icon: "headphones", text: "イヤホンの音量は60%以下に")
                    TipRow(icon: "clock", text: "1時間ごとに耳を休ませる")
                    TipRow(icon: "cross.case", text: "気になったら早めに耳鼻科へ")
                }
                .padding(20)
                .background(Colors.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                BigButton(title: "もう一度テスト", icon: "arrow.counterclockwise") {
                    onRetry()
                }

                Spacer().frame(height: 40)
            }
        }
    }
}

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Colors.accent)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Colors.text)
        }
    }
}

// MARK: - Shared Components

private struct BigButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                Text(title)
                    .font(.system(size: 22, weight: .black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Colors.accent, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 40)
        }
    }
}

private enum Colors {
    static let bg = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let accent = Color(red: 0.25, green: 0.52, blue: 0.85)
    static let text = Color(red: 0.15, green: 0.15, blue: 0.20)
    static let sub = Color(red: 0.45, green: 0.47, blue: 0.52)
}
