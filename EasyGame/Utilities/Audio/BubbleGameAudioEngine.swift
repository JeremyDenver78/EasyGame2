import Foundation
import AVFoundation
import Accelerate

// MARK: - Bubble Game Audio Engine
class BubbleGameAudioEngine {
    static let shared = BubbleGameAudioEngine()

    // MARK: - Transient Properties
    // We make these optional so we can destroy/recreate them on demand.
    // This prevents "stale graph" crashes when switching views.
    private var engine: AVAudioEngine?
    private var mainMixer: AVAudioMixerNode?
    private var dronePlayer: AVAudioPlayerNode?
    private var collisionPlayer: AVAudioPlayerNode?
    private let audioQueue = DispatchQueue(label: "com.antigravity.bubbleAudioQueue")

    private var isPlaying = false

    private init() {}

    private func setupAudioSession() {
        do {
            // Force specific category for this game
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Bubble Audio Session Active")
        } catch {
            print("❌ Bubble Audio Session Failed: \(error)")
        }
    }

    // MARK: - Lifecycle Management

    private func createEngine() {
        // Always rebuild a fresh engine to avoid stale graphs
        let newEngine = AVAudioEngine()
        let newDrone = AVAudioPlayerNode()
        let newCollision = AVAudioPlayerNode()
        let newMixer = newEngine.mainMixerNode // Singleton accessor
        let format = newEngine.outputNode.inputFormat(forBus: 0)

        // Attach
        newEngine.attach(newDrone)
        newEngine.attach(newCollision)

        // Connect directly to mixer/output to avoid graph complexity
        newEngine.connect(newDrone, to: newMixer, format: format)
        newEngine.connect(newCollision, to: newMixer, format: format)
        newEngine.connect(newMixer, to: newEngine.outputNode, format: format)

        // Assign
        self.engine = newEngine
        self.dronePlayer = newDrone
        self.collisionPlayer = newCollision
        self.mainMixer = newMixer

        newEngine.prepare()
        print("✓ Bubble Audio Engine Created (Fresh)")
    }

    private func tearDownEngine() {
        isPlaying = false

        if let engine = engine {
            if engine.isRunning { engine.stop() }
        }

        // Release strong references to let ARC clean up
        dronePlayer = nil
        collisionPlayer = nil
        mainMixer = nil
        engine = nil

        print("✓ Bubble Audio Engine Destroyed")
    }

    // MARK: - Public Controls

    func startAmbientDrone() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isPlaying else { return }

            // Always reactivate the session first
            self.setupAudioSession()

            // Rebuild engine fresh for this start
            self.tearDownEngine()
            self.createEngine()

            guard let engine = self.engine,
                  let dronePlayer = self.dronePlayer else { return }

            guard let droneBuffer = self.generateAmbientDrone(duration: 10.0) else { return }

            // Ensure the engine is running before scheduling
            do {
                if !engine.isRunning {
                    try engine.start()
                }
            } catch {
                print("❌ Failed to start Bubble Engine: \(error)")
                return
            }

            // Ensure player is still attached (defensive)
            if dronePlayer.engine == nil {
                engine.attach(dronePlayer)
                let format = engine.mainMixerNode.outputFormat(forBus: 0)
                engine.connect(dronePlayer, to: engine.mainMixerNode, format: format)
            }

            // Reset and schedule
            dronePlayer.stop()
            dronePlayer.reset()
            dronePlayer.scheduleBuffer(droneBuffer, at: nil, options: .loops, completionHandler: nil)

            dronePlayer.volume = 0.15
            dronePlayer.play()
            self.isPlaying = true
            print("✓ Bubble Audio Playing")
        }
    }

    func stopAmbientDrone() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = false
            self.dronePlayer?.stop()
            self.tearDownEngine()
        }
    }

    func playCollisionSound() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            guard let engine = self.engine,
                  let collisionPlayer = self.collisionPlayer else { return }

            guard let collisionBuffer = self.generateSoftThud(frequency: 180.0, duration: 0.4) else { return }

            if !engine.isRunning {
                try? engine.start()
            }

            if collisionPlayer.engine == nil {
                engine.attach(collisionPlayer)
                let format = engine.mainMixerNode.outputFormat(forBus: 0)
                engine.connect(collisionPlayer, to: engine.mainMixerNode, format: format)
            }

            collisionPlayer.scheduleBuffer(collisionBuffer, at: nil, options: [], completionHandler: nil)
            collisionPlayer.volume = 0.25

            if !collisionPlayer.isPlaying {
                collisionPlayer.play()
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
