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
        setupAudioSession()
        setupAudioGraph()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Bubble Audio Session configured")
        } catch {
            print("❌ Bubble Audio Session Failed: \(error)")
        }
    }

    private func setupAudioGraph() {
        // Setup reverb for spacious ambient feel
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 30

        // Attach nodes
        engine.attach(dronePlayer)
        engine.attach(collisionPlayer)
        engine.attach(reverb)

        // Connect graph: Players -> Reverb -> MainMixer -> Output
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

        engine.connect(dronePlayer, to: reverb, format: format)
        engine.connect(collisionPlayer, to: reverb, format: format)
        engine.connect(reverb, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)

        print("✓ Bubble Audio Graph initialized")
    }

    // MARK: - Background Ambient Drone

    func startAmbientDrone() {
        guard !isPlaying else { return }

        // Generate Indian-style ambient drone
        let droneBuffer = generateAmbientDrone(duration: 10.0)

        // Schedule and loop
        dronePlayer.scheduleBuffer(droneBuffer, at: nil, options: .loops, completionHandler: nil)

        // Start engine and player
        if !engine.isRunning {
            do {
                try engine.start()
                print("✓ Bubble Audio Engine started")
            } catch {
                print("❌ Failed to start engine: \(error)")
                return
            }
        }

        dronePlayer.volume = 0.15 // Very soft, calming volume
        dronePlayer.play()
        isPlaying = true

        print("✓ Ambient drone started")
    }

    func stopAmbientDrone() {
        guard isPlaying else { return }

        dronePlayer.stop()
        isPlaying = false

        print("✓ Ambient drone stopped")
    }

    // MARK: - Collision Sound

    func playCollisionSound() {
        guard engine.isRunning else { return }

        // Generate soft, gentle thud
        let collisionBuffer = generateSoftThud(frequency: 180.0, duration: 0.4)

        collisionPlayer.scheduleBuffer(collisionBuffer, at: nil, options: [], completionHandler: nil)
        collisionPlayer.volume = 0.25

        if !collisionPlayer.isPlaying {
            collisionPlayer.play()
        }
    }

    // MARK: - Audio Generation

    private func generateAmbientDrone(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Indian-style drone frequencies (Shruti box inspiration)
        let baseFreq = 110.0 // A2 - grounding base note
        let fifthFreq = 165.0 // E3 - perfect fifth above
        let octaveFreq = 220.0 // A3 - octave above base

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Layer 1: Base drone with subtle FM
            let fmMod1 = sin(2.0 * .pi * 0.3 * t) * 0.5 // Very slow modulation
            let base = sin(2.0 * .pi * baseFreq * t + fmMod1)

            // Layer 2: Perfect fifth
            let fmMod2 = sin(2.0 * .pi * 0.2 * t) * 0.3
            let fifth = sin(2.0 * .pi * fifthFreq * t + fmMod2)

            // Layer 3: Octave overtone
            let fmMod3 = sin(2.0 * .pi * 0.25 * t) * 0.4
            let octave = sin(2.0 * .pi * octaveFreq * t + fmMod3)

            // Mix layers with balanced volumes
            let mixed = (base * 0.5) + (fifth * 0.3) + (octave * 0.2)

            // Seamless loop envelope
            let loopEnvelope: Double
            let fadeLength = 0.5 // 500ms crossfade
            if t < fadeLength {
                loopEnvelope = t / fadeLength
            } else if t > (duration - fadeLength) {
                loopEnvelope = (duration - t) / fadeLength
            } else {
                loopEnvelope = 1.0
            }

            let finalSample = Float(mixed * loopEnvelope * 0.4) // Soft master volume
            channels[0][i] = finalSample // Left
            channels[1][i] = finalSample // Right
        }

        return buffer
    }

    private func generateSoftThud(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate

            // Soft thud: Low sine with fast exponential decay
            let envelope = exp(-8.0 * t) // Quick decay

            // Mix low frequency with slight harmonics for warmth
            let fundamental = sin(2.0 * .pi * frequency * t)
            let harmonic = sin(2.0 * .pi * frequency * 2.0 * t) * 0.3

            let sample = (fundamental + harmonic) * envelope

            let finalSample = Float(sample * 0.5) // Gentle volume
            channels[0][i] = finalSample // Left
            channels[1][i] = finalSample // Right
        }

        return buffer
    }
}
