import Foundation
import AVFoundation
import Accelerate

// MARK: - Bubble Game Audio Engine
class BubbleGameAudioEngine {
    static let shared = BubbleGameAudioEngine()

    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode

    // Audio nodes
    private let dronePlayer = AVAudioPlayerNode()
    private let collisionPlayer = AVAudioPlayerNode()
    private let reverb = AVAudioUnitReverb()

    private var isPlaying = false

    private init() {
        mainMixer = engine.mainMixerNode
        // Note: We intentionally do not setup the session in init.
        // We do it on 'start' to ensure we override any settings from other games.
    }

    private func setupAudioSession() {
        do {
            // Force session to ambient to ensure clean slate from other games (like HarmonicBloom)
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Bubble Audio Session configured")
        } catch {
            print("❌ Bubble Audio Session Failed: \(error)")
        }
    }

    // MARK: - Graph Management

    private func rebuildGraph() {
        // 1. Stop engine to safely modify graph
        engine.stop()

        // 2. Detach all nodes to clear stale state (Critical Fix)
        // If we don't detach, previous broken connections might persist
        engine.detach(dronePlayer)
        engine.detach(collisionPlayer)
        engine.detach(reverb)

        // 3. Attach nodes
        engine.attach(dronePlayer)
        engine.attach(collisionPlayer)
        engine.attach(reverb)

        // 4. Define format (standard 44.1k stereo)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            print("❌ Failed to create audio format")
            return
        }

        // 5. Connect Nodes: Players -> Reverb -> MainMixer
        engine.connect(dronePlayer, to: reverb, format: format)
        engine.connect(collisionPlayer, to: reverb, format: format)
        engine.connect(reverb, to: mainMixer, format: format)

        // 6. Connect to Output (Use nil format to allow engine to handle hardware mixing)
        engine.connect(mainMixer, to: engine.outputNode, format: nil)

        // 7. Configure Reverb
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 30

        print("✓ Bubble Audio Graph Rebuilt")
    }

    // MARK: - Background Ambient Drone

    func startAmbientDrone() {
        guard !isPlaying else { return }

        // 1. Reset Session (Fixes category conflicts)
        setupAudioSession()

        // 2. Rebuild Graph (Fixes 'disconnected state' crash)
        rebuildGraph()

        // 3. Generate Buffer
        guard let droneBuffer = generateAmbientDrone(duration: 10.0) else { return }

        // 4. Schedule Loop
        if !dronePlayer.isPlaying {
            dronePlayer.scheduleBuffer(droneBuffer, at: nil, options: .loops, completionHandler: nil)
        }

        // 5. Start Engine
        do {
            try engine.start()
            dronePlayer.volume = 0.15
            dronePlayer.play()
            isPlaying = true
            print("✓ Bubble Audio Started")
        } catch {
            print("❌ Failed to start Bubble Audio Engine: \(error)")
            isPlaying = false
        }
    }

    func stopAmbientDrone() {
        guard isPlaying else { return }

        dronePlayer.stop()
        engine.stop()
        isPlaying = false

        print("✓ Bubble Audio Stopped")
    }

    // MARK: - Collision Sound

    func playCollisionSound() {
        // Only play if engine is actually running to avoid crashes
        guard engine.isRunning else { return }

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
            if t < fadeLength {
                loopEnvelope = t / fadeLength
            } else if t > (duration - fadeLength) {
                loopEnvelope = (duration - t) / fadeLength
            } else {
                loopEnvelope = 1.0
            }

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
