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
    private var reverb: AVAudioUnitReverb?

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
        // 1. Create fresh instances
        let newEngine = AVAudioEngine()
        let newDrone = AVAudioPlayerNode()
        let newCollision = AVAudioPlayerNode()
        let newReverb = AVAudioUnitReverb()
        let newMixer = newEngine.mainMixerNode // Singleton accessor

        // 2. Configure Nodes
        newReverb.loadFactoryPreset(.mediumHall)
        newReverb.wetDryMix = 30

        // 3. Attach
        newEngine.attach(newDrone)
        newEngine.attach(newCollision)
        newEngine.attach(newReverb)

        // 4. Connect
        // Use standard format. If this fails, we catch it in start()
        if let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) {
            newEngine.connect(newDrone, to: newReverb, format: format)
            newEngine.connect(newCollision, to: newReverb, format: format)
            newEngine.connect(newReverb, to: newMixer, format: format)

            // Connect mixer to output with nil format (hardware handling)
            newEngine.connect(newMixer, to: newEngine.outputNode, format: nil)
        }

        // 5. Assign to properties
        self.engine = newEngine
        self.mainMixer = newMixer
        self.dronePlayer = newDrone
        self.collisionPlayer = newCollision
        self.reverb = newReverb

        print("✓ Bubble Audio Engine Created (Fresh)")
    }

    private func tearDownEngine() {
        if let engine = engine {
            if engine.isRunning { engine.stop() }
        }

        // Release strong references to let ARC clean up
        dronePlayer = nil
        collisionPlayer = nil
        reverb = nil
        mainMixer = nil
        engine = nil

        print("✓ Bubble Audio Engine Destroyed")
    }

    // MARK: - Public Controls

    func startAmbientDrone() {
        guard !isPlaying else { return }

        // 1. Ensure clean slate
        tearDownEngine()
        setupAudioSession()
        createEngine()

        guard let engine = engine, let dronePlayer = dronePlayer else { return }

        // 2. Generate Buffer
        guard let droneBuffer = generateAmbientDrone(duration: 10.0) else { return }

        // 3. Schedule
        dronePlayer.scheduleBuffer(droneBuffer, at: nil, options: .loops, completionHandler: nil)

        // 4. Start
        do {
            try engine.start()
            dronePlayer.volume = 0.15
            dronePlayer.play()
            isPlaying = true
            print("✓ Bubble Audio Playing")
        } catch {
            print("❌ Failed to start Bubble Engine: \(error)")
            // If start fails, cleanup immediately
            tearDownEngine()
            isPlaying = false
        }
    }

    func stopAmbientDrone() {
        isPlaying = false
        // Completely destroy the engine when leaving the game
        tearDownEngine()
    }

    func playCollisionSound() {
        // Guard against calling play on a nil or non-running engine
        guard let engine = engine, engine.isRunning, let collisionPlayer = collisionPlayer else { return }

        guard let collisionBuffer = generateSoftThud(frequency: 180.0, duration: 0.4) else { return }

        collisionPlayer.scheduleBuffer(collisionBuffer, at: nil, options: [], completionHandler: nil)
        collisionPlayer.volume = 0.25

        if !collisionPlayer.isPlaying {
            collisionPlayer.play()
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
