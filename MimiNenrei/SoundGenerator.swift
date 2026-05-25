import AVFoundation
import Observation

@Observable
final class SoundGenerator {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var buffer: AVAudioPCMBuffer?
    var isPlaying = false

    func play(frequency: Double, duration: Double = 2.0) {
        stop()

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buf.frameLength = frameCount
        guard let data = buf.floatChannelData?[0] else { return }

        let amplitude: Float = 0.5
        for i in 0..<Int(frameCount) {
            let theta = 2.0 * Float.pi * Float(frequency) * Float(i) / Float(sampleRate)
            // Fade in/out to avoid clicks
            let fadeFrames = min(Int(sampleRate * 0.05), Int(frameCount) / 4)
            var envelope: Float = 1.0
            if i < fadeFrames {
                envelope = Float(i) / Float(fadeFrames)
            } else if i > Int(frameCount) - fadeFrames {
                envelope = Float(Int(frameCount) - i) / Float(fadeFrames)
            }
            data[i] = amplitude * envelope * sin(theta)
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            return
        }

        player.play()
        player.scheduleBuffer(buf) { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
            }
        }

        audioEngine = engine
        playerNode = player
        buffer = buf
        isPlaying = true
    }

    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        buffer = nil
        isPlaying = false
    }
}
