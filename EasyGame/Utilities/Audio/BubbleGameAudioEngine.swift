import Foundation
import AVFoundation
import Accelerate

// MARK: - Bubble Game Audio Engine (Singleton)
class BubbleGameAudioEngine {
    static let shared = BubbleGameAudioEngine()

    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let dronePlayer = AVAudioPlayerNode()
    private let collisionPlayer = AVAudioPlayerNode()
    private let audioQueue = DispatchQueue(label: "com.antigravity.bubbleAudioQueue")

    private var droneBuffer: AVAudioPCMBuffer?
    private var isPlaying = false

    private init() {
        mainMixer = engine.mainMixerNode
        setupAudioSession()
        setupGraph()
        prepareEngine()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Bubble Audio Session Active")
        } catch {
            print("❌ Bubble Audio Session Failed: \(error)")
        }
    }

    // MARK: - Engine Setup
    private func setupGraph() {
        engine.attach(dronePlayer)
        engine.attach(collisionPlayer)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

        engine.connect(dronePlayer, to: mainMixer, format: format)
        engine.connect(collisionPlayer, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)

        print("✓ Bubble Audio Graph Initialized")
    }

    private func prepareEngine() {
        engine.prepare()
        startEngineIfNeeded()
        prepareDroneBuffer()
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
            print("✓ Bubble Audio Engine Started")
        } catch {
            print("❌ Failed to start Bubble Engine: \(error)")
        }
    }

    private func prepareDroneBuffer() {
        guard droneBuffer == nil else { return }
        guard let buffer = generateAmbientDrone(duration: 10.0) else { return }

        droneBuffer = buffer
        dronePlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        dronePlayer.volume = 0.15
    }

    // MARK: - Public Controls

    func startAmbientDrone() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isPlaying else { return }

            // Ensure session stays active if another view changed it
            self.setupAudioSession()
            self.startEngineIfNeeded()
            self.prepareDroneBuffer()

            guard self.dronePlayer.engine != nil else { return }

            self.dronePlayer.play()
            self.isPlaying = true
            print("✓ Bubble Audio Playing")
        }
    }

    func stopAmbientDrone() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = false
            self.dronePlayer.pause()
        }
    }

    func playCollisionSound() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            self.startEngineIfNeeded()

            guard let collisionBuffer = self.generateSoftThud(frequency: 180.0, duration: 0.4) else { return }

            if self.collisionPlayer.engine == nil {
                let format = self.mainMixer.outputFormat(forBus: 0)
                self.engine.attach(self.collisionPlayer)
                self.engine.connect(self.collisionPlayer, to: self.mainMixer, format: format)
            }

            self.collisionPlayer.scheduleBuffer(collisionBuffer, at: nil, options: [], completionHandler: nil)
            self.collisionPlayer.volume = 0.25

            if !self.collisionPlayer.isPlaying {
                self.collisionPlayer.play()
            }
        }
    }

    // MARK: - Audio Generation

    private func generateAmbientDrone(duration: Double) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else { return nil }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channels = buffer.floatChannelData else { return nil }

        let baseFreq = 110.0 // A2
        let fifthFreq = 165.0 // E3
        let octaveFreq = 220.0 // A3

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let fmMod1 = sin(2.0 * .pi * 0.3 * t) * 0.5
            let base = sin(2.0 * .pi * baseFreq * t + fmMod1)
            let fmMod2 = sin(2.0 * .pi * 0.2 * t) * 0.3
            let fifth = sin(2.0 * .pi * fifthFreq * t + fmMod2)
            let fmMod3 = sin(2.0 * .pi * 0.25 * t) * 0.4
            let octave = sin(2.0 * .pi * octaveFreq * t + fmMod3)
            let mixed = (base * 0.5) + (fifth * 0.3) + (octave * 0.2)

            let loopEnvelope: Double
            let fadeLength = 0.5
            if t < fadeLength { loopEnvelope = t / fadeLength }
            else if t > (duration - fadeLength) { loopEnvelope = (duration - t) / fadeLength }
            else { loopEnvelope = 1.0 }

            let finalSample = Float(mixed * loopEnvelope * 0.4)
            channels[0][i] = finalSample
            channels[1][i] = finalSample
        }
        return buffer
    }

    private func generateSoftThud(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else { return nil }
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channels = buffer.floatChannelData else { return nil }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-8.0 * t)
            let fundamental = sin(2.0 * .pi * frequency * t)
            let harmonic = sin(2.0 * .pi * frequency * 2.0 * t) * 0.3
            let sample = (fundamental + harmonic) * envelope
            let finalSample = Float(sample * 0.5)
            channels[0][i] = finalSample
            channels[1][i] = finalSample
        }
        return buffer
    }
}
