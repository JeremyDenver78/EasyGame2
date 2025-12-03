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
    private var isInitialized = false

    private init() {
        mainMixer = engine.mainMixerNode
        setupAudioSession()
        // Defer graph setup until first use to avoid conflicts
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

    // MARK: - Graph Management

    private func rebuildGraph() {
        // 1. Ensure nodes are attached (safe to call even if already attached)
        if dronePlayer.engine == nil { engine.attach(dronePlayer) }
        if collisionPlayer.engine == nil { engine.attach(collisionPlayer) }
        if reverb.engine == nil { engine.attach(reverb) }

        // 2. Define internal processing format (44.1kHz stereo)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            print("❌ Failed to create audio format")
            return
        }

        // 3. Connect Nodes
        // Note: engine.connect re-establishes connections if they were broken
        engine.connect(dronePlayer, to: reverb, format: format)
        engine.connect(collisionPlayer, to: reverb, format: format)
        engine.connect(reverb, to: mainMixer, format: format)

        // 4. Connect to Output
        // CRITICAL FIX: Use nil format to allow engine to handle hardware sample rate mixing (e.g. 48k output)
        engine.connect(mainMixer, to: engine.outputNode, format: nil)

        // 5. Configure Reverb
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 30

        isInitialized = true
        print("✓ Bubble audio graph initialized")
    }

    // MARK: - Background Ambient Drone

    func startAmbientDrone() {
        guard !isPlaying else { return }

        do {
            // CRITICAL FIX: Ensure graph is valid before starting.
            // Other audio engines in the app might have invalidated this graph.
            rebuildGraph()

            guard isInitialized else {
                print("❌ Audio graph not initialized")
                return
            }

            // Generate buffer if needed (buffer generation is fast enough to do here or cache)
            guard let droneBuffer = generateAmbientDrone(duration: 10.0) else {
                print("❌ Failed to generate drone buffer")
                return
            }

            // Schedule and loop
            if !dronePlayer.isPlaying {
                dronePlayer.scheduleBuffer(droneBuffer, at: nil, options: .loops, completionHandler: nil)
            }

            // Start engine
            if !engine.isRunning {
                try engine.start()
                print("✓ Bubble Audio Engine started")
            }

            dronePlayer.volume = 0.15
            dronePlayer.play()
            isPlaying = true

            print("✓ Ambient drone started")
        } catch {
            print("❌ Failed to start ambient drone: \(error)")
            isPlaying = false
        }
    }

    func stopAmbientDrone() {
        guard isPlaying else { return }

        dronePlayer.stop()
        isPlaying = false

        // Optional: Pause engine to save resources, but keep graph intact
        engine.pause()

        print("✓ Ambient drone stopped")
    }

    // MARK: - Collision Sound

    func playCollisionSound() {
        do {
            // Safety check: ensure player is connected
            if collisionPlayer.engine == nil {
                rebuildGraph()
            }

            guard isInitialized else {
                print("❌ Cannot play collision: audio graph not initialized")
                return
            }

            // Ensure engine is running
            if !engine.isRunning {
                try engine.start()
            }

            guard let collisionBuffer = generateSoftThud(frequency: 180.0, duration: 0.4) else {
                print("❌ Failed to generate collision buffer")
                return
            }

            collisionPlayer.scheduleBuffer(collisionBuffer, at: nil, options: [], completionHandler: nil)
            collisionPlayer.volume = 0.25

            if !collisionPlayer.isPlaying {
                collisionPlayer.play()
            }
        } catch {
            print("❌ Failed to play collision sound: \(error)")
        }
    }

    // MARK: - Audio Generation

    private func generateAmbientDrone(duration: Double) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            print("❌ Failed to create drone format")
            return nil
        }

        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to create drone buffer")
            return nil
        }
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else {
            print("❌ Failed to get drone channel data")
            return nil
        }

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
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            print("❌ Failed to create thud format")
            return nil
        }

        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to create thud buffer")
            return nil
        }
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else {
            print("❌ Failed to get thud channel data")
            return nil
        }

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
