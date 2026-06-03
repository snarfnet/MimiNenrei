import Observation
import SwiftUI

struct FrequencyStep: Identifiable {
    let id = UUID()
    let frequency: Double
    let label: String
    let ageRange: String
}

@Observable
final class HearingTest {
    let steps: [FrequencyStep] = [
        FrequencyStep(frequency: 8000, label: "8,000 Hz", ageRange: "70歳以上"),
        FrequencyStep(frequency: 10000, label: "10,000 Hz", ageRange: "60代"),
        FrequencyStep(frequency: 12000, label: "12,000 Hz", ageRange: "50代"),
        FrequencyStep(frequency: 14000, label: "14,000 Hz", ageRange: "40代"),
        FrequencyStep(frequency: 15000, label: "15,000 Hz", ageRange: "30代"),
        FrequencyStep(frequency: 16000, label: "16,000 Hz", ageRange: "20代"),
        FrequencyStep(frequency: 17000, label: "17,000 Hz", ageRange: "10代"),
        FrequencyStep(frequency: 18000, label: "18,000 Hz", ageRange: "10歳未満")
    ]

    var currentIndex = 0
    var results: [Bool] = []
    var isFinished = false
    var earAge = 0
    var maxHeard: Double = 0

    var currentStep: FrequencyStep? {
        guard currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }

    var progress: Double {
        Double(currentIndex) / Double(steps.count)
    }

    var heardCount: Int {
        results.filter { $0 }.count
    }

    func answer(heard: Bool) {
        results.append(heard)
        if heard {
            maxHeard = steps[currentIndex].frequency
        }
        currentIndex += 1
        if currentIndex >= steps.count {
            finish()
        }
    }

    func finish() {
        isFinished = true
        earAge = calculateAge()
    }

    func reset() {
        currentIndex = 0
        results = []
        isFinished = false
        earAge = 0
        maxHeard = 0
    }

    private func calculateAge() -> Int {
        if maxHeard >= 18000 { return 5 }
        if maxHeard >= 17000 { return 15 }
        if maxHeard >= 16000 { return 25 }
        if maxHeard >= 15000 { return 35 }
        if maxHeard >= 14000 { return 45 }
        if maxHeard >= 12000 { return 55 }
        if maxHeard >= 10000 { return 65 }
        if maxHeard >= 8000 { return 75 }
        return 80
    }

    var ageComment: String {
        switch earAge {
        case ...15:
            return "かなり若い耳です。高い音までしっかり拾えています。WHOは85dB以上の騒音を避けるよう推奨しています。"
        case ...25:
            return "とても良い聞こえ方です。NIH(米国立衛生研究所)によると、騒音への長時間曝露が聴力低下の主因です。"
        case ...35:
            return "まだまだ良好です。WHOの報告では、イヤホンの音量を60%以下に保つことが聴力保護に有効です。"
        case ...45:
            return "年齢相応の範囲です(NIDCD資料)。耳を休ませる時間も大切です。"
        case ...55:
            return "高音域が少し聞こえにくくなっています。NIDCDによると加齢性難聴は徐々に進行します。大音量は控えめに。"
        case ...65:
            return "高音域の聞き取りが弱めです。NIDCDは定期的な聴力検査を推奨しています。気になる場合は専門医に相談しましょう。"
        default:
            return "高い音がかなり聞こえにくい状態です。WHOとNIDCDは早期の専門医受診を推奨しています。耳鼻科での相談を検討してください。"
        }
    }
}
