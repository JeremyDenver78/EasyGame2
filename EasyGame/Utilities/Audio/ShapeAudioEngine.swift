import Foundation
import AVFoundation

// MARK: - Shape Audio Engine (SINGLETON - Dynamic Node Management)
class ShapeAudioEngine {
    static let shared = ShapeAudioEngine()

    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let reverb = AVAudioUnitReverb()
    private let collisionPlayer = AVAudioPlayerNode()

    // Track active player nodes (created dynamically)
    private var activeNodes: [UUID: AVAudioPlayerNode] = [:]

    private init() {
        mainMixer = engine.mainMixerNode
        setupSession()
        setupStaticGraph()
    }

    private func setupSession() {
        do {
            // CRITICAL: Configure session to mix with other audio
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Shape Audio Session configured: .ambient with .mixWithOthers")
        } catch {
            print("❌ Shape Audio Session Failed: \(error)")
        }
    }

    private func setupStaticGraph() {
        // Setup reverb for ambient feel
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 40

        // Attach static nodes (reverb, collision player)
        engine.attach(reverb)
        engine.attach(collisionPlayer)

        // Connect static graph: Reverb -> MainMixer -> Output
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

        engine.connect(reverb, to: mainMixer, format: format)
        engine.connect(collisionPlayer, to: reverb, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)

        print("✓ Shape Audio Graph initialized: Static nodes connected")
    }

    // MARK: - Continuous Loop Management

    func startLoop(for shapeID: UUID, type: ShapeType, volume: Double = 0.5) {
        // Prevent duplicates
        guard activeNodes[shapeID] == nil else {
            print("⚠️ Loop already exists for shape \(shapeID)")
            return
        }

        // 1. Create new player node
        let player = AVAudioPlayerNode()

        // 2. CRITICAL: Attach node to engine FIRST
        engine.attach(player)

        // 3. CRITICAL: Use mixer's output format for compatibility
        let mixerFormat = mainMixer.outputFormat(forBus: 0)
        engine.connect(player, to: mainMixer, format: mixerFormat)

        // 4. Generate buffer and schedule
        let buffer = generateContinuousLoop(frequency: type.baseFrequency, duration: 5.0, type: type)
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)

        // 5. Ensure engine is running BEFORE playing
        if !engine.isRunning {
            do {
                try engine.start()
                print("✓ Engine started")
            } catch {
                print("❌ Failed to start engine: \(error)")
                return
            }
        }

        // 6. CRITICAL: Verify player is connected before playing
        guard player.engine != nil else {
            print("❌ Player not connected to engine")
            return
        }

        // 7. NOW safe to play
        player.play()
        player.volume = Float(volume)

        // 8. Track this node
        activeNodes[shapeID] = player

        print("✓ Started loop for \(type.rawValue) at \(type.baseFrequency)Hz (\(activeNodes.count) active)")
    }

    func stopLoop(for shapeID: UUID, fadeDuration: TimeInterval = 0.5) {
        guard let player = activeNodes[shapeID] else { return }

        // Remove from tracking IMMEDIATELY to prevent duplicate cleanup
        activeNodes.removeValue(forKey: shapeID)

        // Fade out
        player.volume = 0.0

        // Schedule cleanup after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
            guard let self = self else { return }

            // 1. Stop playback
            player.stop()

            // 2. CRITICAL: Only disconnect if node is still in engine
            if player.engine != nil {
                // Disconnect node input (safe disconnection)
                self.engine.disconnectNodeInput(player)

                // Detach from engine
                self.engine.detach(player)
            }

            print("✓ Stopped loop (\(self.activeNodes.count) active)")
        }
    }

    func stopAll() {
        let allIDs = Array(activeNodes.keys)
        for id in allIDs {
            stopLoop(for: id, fadeDuration: 0.2)
        }
    }

    // MARK: - Collision Sound (Reuse single player)

    func playCollisionSound(volume: Double = 0.3) {
        guard engine.isRunning else {
            try? engine.start()
            return
        }

        // Generate short chime
        let frequency = Double.random(in: 800.0...1200.0)
        let buffer = generateCollisionChime(frequency: frequency, duration: 0.3)

        // Schedule on the dedicated collision player (already connected)
        collisionPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        collisionPlayer.volume = Float(volume)

        if !collisionPlayer.isPlaying {
            collisionPlayer.play()
        }
    }

    // MARK: - Buffer Generators

    private func generateContinuousLoop(frequency: Double, duration: Double, type: ShapeType) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Generate waveform based on shape type
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let phase = 2.0 * .pi * frequency * t

            var sample: Double

            switch type {
            case .circle: // Pure sine (bell-like)
                sample = sin(phase)

            case .triangle: // Triangle wave (bright, chime-like)
                let p = 2.0 * frequency * t
                sample = 2.0 * abs(2.0 * (p - floor(p + 0.5))) - 1.0

            case .square: // Warm pad (sine + harmonics)
                sample = sin(phase) + 0.3 * sin(2.0 * phase) + 0.15 * sin(3.0 * phase)

            case .hexagon: // Rich harmonic (organ-like)
                sample = sin(phase) + 0.5 * sin(1.5 * phase) + 0.25 * sin(2.5 * phase)

            case .star: // FM synthesis (shimmering)
                let modulator = sin(2.0 * .pi * 5.0 * t) * 2.0
                sample = sin(phase + modulator)
            }

            // Smooth envelope for seamless looping
            let loopEnvelope: Double
            let fadeLength = 0.05 // 50ms crossfade
            if t < fadeLength {
                loopEnvelope = t / fadeLength // Fade in
            } else if t > (duration - fadeLength) {
                loopEnvelope = (duration - t) / fadeLength // Fade out
            } else {
                loopEnvelope = 1.0
            }

            let finalSample = Float(sample * loopEnvelope * 0.3) // 0.3 master volume
            channels[0][i] = finalSample // Left
            channels[1][i] = finalSample // Right
        }

        return buffer
    }

    private func generateCollisionChime(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Short, percussive chime with quick decay
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-8.0 * t) // Fast exponential decay
            let sample = sin(2.0 * .pi * frequency * t) * envelope

            let finalSample = Float(sample * 0.4)
            channels[0][i] = finalSample // Left
            channels[1][i] = finalSample // Right
        }

        return buffer
    }
}
