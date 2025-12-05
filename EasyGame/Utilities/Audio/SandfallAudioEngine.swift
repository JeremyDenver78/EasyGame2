import Foundation
import AVFoundation

// MARK: - Sandfall Audio Engine (gentle landing cues)
final class SandfallAudioEngine {
    static let shared = SandfallAudioEngine()

    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let sandPlayer = AVAudioPlayerNode()
    private let audioQueue = DispatchQueue(label: "com.antigravity.sandfall.audio")

    private var sandHitBuffer: AVAudioPCMBuffer?
    private var lastTriggerTime = DispatchTime(uptimeNanoseconds: 0)

    private init() {
        mainMixer = engine.mainMixerNode
        setupSession()
        setupGraph()
        prepareEngine()
    }

    private func setupSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Sandfall Audio Session configured")
        } catch {
            print("❌ Sandfall Audio Session failed: \(error)")
        }
    }

    private func setupGraph() {
        engine.attach(sandPlayer)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            print("❌ Sandfall audio format unavailable")
            return
        }

        engine.connect(sandPlayer, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)
    }

    private func prepareEngine() {
        engine.prepare()
        startEngineIfNeeded()
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("❌ Sandfall engine start failed: \(error)")
        }
    }

    // Prepare buffers and engine (call on appear)
    func startSandfall() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            self.setupSession()
            self.startEngineIfNeeded()
            self.prepareSandHitBuffer()
        }
    }

    func stopSandfall() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.sandPlayer.stop()
            self.sandPlayer.reset()
            self.lastTriggerTime = DispatchTime(uptimeNanoseconds: 0)
        }
    }

    func playLandingSound(intensity: Double) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.startEngineIfNeeded()
            self.prepareSandHitBuffer()
            guard let buffer = self.sandHitBuffer else { return }

            if self.sandPlayer.engine == nil {
                let format = self.mainMixer.outputFormat(forBus: 0)
                self.engine.attach(self.sandPlayer)
                self.engine.connect(self.sandPlayer, to: self.mainMixer, format: format)
            }

            let clamped = max(0.05, min(0.35, intensity * 0.25 + 0.06))

            // Rate-limit to prevent chattering
            let now = DispatchTime.now()
            let minInterval: UInt64 = 120_000_000 // 120ms
            if now.uptimeNanoseconds - self.lastTriggerTime.uptimeNanoseconds < minInterval {
                if self.sandPlayer.isPlaying {
                    self.sandPlayer.volume = Float(clamped)
                }
                return
            }

            self.lastTriggerTime = now

            self.sandPlayer.stop()
            self.sandPlayer.reset()
            self.sandPlayer.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
            self.sandPlayer.volume = Float(clamped * 0.75) // soften overall level
            self.sandPlayer.play()
        }
    }

    private func prepareSandHitBuffer() {
        guard sandHitBuffer == nil else { return }
        sandHitBuffer = generateSandHit(duration: 0.8)
    }

    // MARK: - Buffer Generator
    // Very soft filtered noise burst with gentle envelope
    private func generateSandHit(duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            print("❌ Sandfall hit format unavailable")
            return nil
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Sandfall hit buffer allocation failed")
            return nil
        }
        buffer.frameLength = frameCount
        guard let channels = buffer.floatChannelData else {
            print("❌ Sandfall hit channels unavailable")
            return nil
        }

        var smoothedNoise: Double = 0.0
        var lowDrift: Double = 0.0
        let smoothing: Double = 0.985 // very soft, low-passed
        let noiseMix: Double = 0.09
        let driftMix: Double = 0.04
        let fadeLength = 0.12
        let release = 0.5

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Smooth (brown-ish) noise for sand texture
            let white = Double.random(in: -1.0...1.0)
            smoothedNoise = smoothing * smoothedNoise + (1.0 - smoothing) * white

            // Low drifting tone for body
            let slowPhase = 2.0 * .pi * 42.0 * t
            lowDrift = sin(slowPhase) * 0.3

            var sample = smoothedNoise * noiseMix + lowDrift * driftMix

            // Gentle fade in/out for one-shot
            let fadeIn = min(1.0, t / fadeLength)
            let fadeOut = min(1.0, (duration - t) / release)
            let env = min(fadeIn, fadeOut)
            sample *= env

            let final = Float(sample)
            channels[0][i] = final
            channels[1][i] = final
        }

        return buffer
    }
}
