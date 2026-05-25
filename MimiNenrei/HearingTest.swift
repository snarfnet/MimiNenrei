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
        FrequencyStep(frequency: 18000, label: "18,000 Hz", ageRange: "10歳未満"),
    ]

    var currentIndex = 0
    var results: [Bool] = []
    var isFinished = false
    var earAge: Int = 0
    var maxHeard: Double = 0

    var currentStep: FrequencyStep? {
        guard currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }

    var progress: Double {
        Double(currentIndex) / Double(steps.count)
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
        case ...15: return "すばらしい！若々しい耳です。"
        case ...25: return "とても良い聴力です。"
        case ...35: return "まだまだ若い耳ですね。"
        case ...45: return "年相応の聴力です。"
        case ...55: return "少し高音が聞きづらくなっています。"
        case ...65: return "高音域が聞こえにくくなっています。"
        default: return "高い音が聞こえにくい状態です。\n気になる場合は耳鼻科の受診をおすすめします。"
        }
    }

    var heardCount: Int {
        results.filter { $0 }.count
    }
}
