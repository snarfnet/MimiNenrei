import SwiftUI

struct ContentView: View {
    @State private var screen: Screen = MimiNenreiApp.isScreenshotMode ? .result : .home
    @State private var test: HearingTest = {
        let t = HearingTest()
        if MimiNenreiApp.isScreenshotMode {
            // Pre-populate: heard up to 15,000 Hz → ear age 35
            t.results = [true, true, true, true, true, false, false, false]
            t.maxHeard = 15000
            t.currentIndex = 8
            t.isFinished = true
            t.earAge = 35
        }
        return t
    }()
    @State private var sound = SoundGenerator()

    enum Screen {
        case home, prepare, test, result
    }

    var body: some View {
        ZStack {
            HeroBackground()

            switch screen {
            case .home:
                HomeView { screen = .prepare }
            case .prepare:
                PrepareView {
                    test.reset()
                    screen = .test
                }
            case .test:
                TestView(test: test, sound: sound) {
                    sound.stop()
                    screen = .result
                }
            case .result:
                ResultView(test: test) {
                    test.reset()
                    screen = .home
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AdMobBannerView(adUnitID: AdMobConfig.bannerAdUnitID)
                .background(.black.opacity(0.72))
        }
    }
}

private struct HomeView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "ear.and.waveform")
                .font(.system(size: 78, weight: .semibold))
                .foregroundStyle(.cyan)
                .shadow(color: .cyan.opacity(0.7), radius: 24)

            VStack(spacing: 10) {
                Text("みみ年齢")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                Text("高い音がどこまで聞こえるかを測って、耳の目安年齢をチェックします。")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)

            Spacer()

            GlassPanel {
                VStack(spacing: 14) {
                    InfoPill(icon: "headphones", text: "イヤホン推奨")
                    InfoPill(icon: "speaker.wave.2", text: "音量は中くらい")
                    InfoPill(icon: "moon.zzz", text: "静かな場所で測定")
                }
            }

            BigButton(title: "テストを始める", icon: "play.fill", action: onStart)
                .padding(.bottom, 34)
        }
    }
}

private struct PrepareView: View {
    let onReady: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            SectionTitle(icon: "headphones.circle.fill", title: "準備")

            GlassPanel {
                VStack(alignment: .leading, spacing: 18) {
                    PrepareRow(num: "1", text: "イヤホンかヘッドホンを装着")
                    PrepareRow(num: "2", text: "音量を中くらいに設定")
                    PrepareRow(num: "3", text: "音が聞こえたらチェック")
                }
            }

            Spacer()
            BigButton(title: "準備できた", icon: "checkmark", action: onReady)
                .padding(.bottom, 40)
        }
    }
}

private struct TestView: View {
    @Bindable var test: HearingTest
    @Bindable var sound: SoundGenerator
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            SectionTitle(icon: "waveform", title: "テスト中")
                .padding(.top, 24)

            ProgressView(value: test.progress)
                .tint(.cyan)
                .scaleEffect(y: 2.2)
                .padding(.horizontal, 32)

            Text("\(test.currentIndex + 1) / \(test.steps.count)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.64))

            Spacer()

            if let step = test.currentStep {
                GlassPanel {
                    VStack(spacing: 18) {
                        Text(step.label)
                            .font(.system(size: 46, weight: .black, design: .monospaced))
                            .foregroundStyle(.cyan)

                        Button {
                            sound.play(frequency: step.frequency, duration: 2.5)
                        } label: {
                            Label(sound.isPlaying ? "再生中..." : "音を鳴らす", systemImage: sound.isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                                .font(.system(size: 21, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background(sound.isPlaying ? Color.orange : Color.cyan, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(.black)
                        }
                    }
                }

                Text("音は聞こえましたか？")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    AnswerButton(title: "聞こえた", icon: "checkmark.circle.fill", color: .green) {
                        answer(true)
                    }
                    AnswerButton(title: "聞こえない", icon: "xmark.circle.fill", color: .red) {
                        answer(false)
                    }
                }
                .padding(.horizontal, 22)
            }

            Spacer().frame(height: 34)
        }
    }

    private func answer(_ heard: Bool) {
        sound.stop()
        test.answer(heard: heard)
        if test.isFinished { onFinish() }
    }
}

private struct ResultView: View {
    let test: HearingTest
    let onRetry: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                SectionTitle(icon: "sparkles", title: "結果")
                    .padding(.top, 24)

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.12), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: min(1, Double(80 - test.earAge) / 80))
                        .stroke(.cyan, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text("みみ年齢")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(test.earAge)")
                            .font(.system(size: 68, weight: .black, design: .rounded))
                            .foregroundStyle(.cyan)
                        Text("歳")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(width: 210, height: 210)

                Text(test.ageComment)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)

                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("テスト詳細")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.white.opacity(0.7))
                        ForEach(Array(test.steps.enumerated()), id: \.element.id) { index, step in
                            HStack {
                                Text(step.label)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                Spacer()
                                Text(step.ageRange)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.55))
                                if index < test.results.count {
                                    Image(systemName: test.results[index] ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(test.results[index] ? .green : .red)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }

                BigButton(title: "もう一度テスト", icon: "arrow.counterclockwise", action: onRetry)
                    .padding(.bottom, 36)
            }
        }
    }
}

private struct HeroBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.05, blue: 0.10).ignoresSafeArea()
            Image("HeroArtwork")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.68)
            LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0.76)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }
}

private struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.16)))
            .padding(.horizontal, 22)
    }
}

private struct SectionTitle: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 30, weight: .black, design: .rounded))
            .foregroundStyle(.white)
    }
}

private struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 17, weight: .bold))
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

private struct PrepareRow: View {
    let num: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text(num)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 38, height: 38)
                .background(.cyan, in: Circle())
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.system(size: 18, weight: .black))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(color.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

private struct BigButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 62)
                .background(.cyan, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: .cyan.opacity(0.35), radius: 18, y: 8)
                .padding(.horizontal, 34)
        }
    }
}
