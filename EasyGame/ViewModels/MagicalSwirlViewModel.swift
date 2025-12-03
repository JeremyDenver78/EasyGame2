import SwiftUI
import Combine
import AVFoundation
import CoreHaptics

// MARK: - Audio Engine (SINGLETON)
class SwirlAudioEngine {
    static let shared = SwirlAudioEngine() // Singleton for stability

    private let engine = AVAudioEngine()
    private let mainMixer = AVAudioMixerNode()
    private let touchPlayer = AVAudioPlayerNode()
    private let movePlayer = AVAudioPlayerNode()
    private let fadePlayer = AVAudioPlayerNode()

    private init() {
        setupSession()
        setupGraph()
        startEngine()
    }

    private func setupSession() {
        do {
            // CRITICAL: Configure session to mix with other audio (music, system sounds)
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✓ Audio Session configured: .ambient with .mixWithOthers")
        } catch {
            print("❌ Audio Session Failed: \(error)")
        }
    }

    private func setupGraph() {
        // 1. Attach ALL Nodes to the engine FIRST
        engine.attach(mainMixer)
        engine.attach(touchPlayer)
        engine.attach(movePlayer)
        engine.attach(fadePlayer)

        // 2. Connect nodes in proper order: Player -> Mixer -> Output
        // Use stereo format (2 channels) for all connections
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

        engine.connect(touchPlayer, to: mainMixer, format: format)
        engine.connect(movePlayer, to: mainMixer, format: format)
        engine.connect(fadePlayer, to: mainMixer, format: format)
        engine.connect(mainMixer, to: engine.outputNode, format: format)

        print("✓ Audio Graph connected: Players -> Mixer -> Output")
    }

    private func startEngine() {
        guard !engine.isRunning else {
            print("✓ Audio Engine already running")
            return
        }

        do {
            try engine.start()
            print("✓ Audio Engine started successfully")
        } catch {
            print("❌ Engine Start Failed: \(error)")
        }
    }

    // MARK: - Playback Methods
    func playTouchSound(volume: Double) {
        // Ensure engine is running
        guard engine.isRunning else {
            try? engine.start()
            return
        }

        // Verify player is connected to engine
        guard touchPlayer.engine != nil else {
            print("❌ Touch player not connected to engine")
            return
        }

        let buffer = generateSineWave(frequency: 440.0, duration: 0.3)
        touchPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        touchPlayer.volume = Float(volume)

        if !touchPlayer.isPlaying {
            touchPlayer.play()
        }
    }

    func playMoveSound(speed: Double, volume: Double) {
        // Ensure engine is running
        guard engine.isRunning else {
            try? engine.start()
            return
        }

        // Verify player is connected to engine
        guard movePlayer.engine != nil else {
            print("❌ Move player not connected to engine")
            return
        }

        if !movePlayer.isPlaying {
            let buffer = generateNoise(duration: 1.0)
            movePlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            movePlayer.play()
        }

        movePlayer.volume = Float(min(1.0, speed / 1000.0) * volume * 0.5)
    }

    func stopMoveSound() {
        guard engine.isRunning, movePlayer.engine != nil else { return }
        movePlayer.stop()
    }

    func playFadeSound(volume: Double) {
        // Ensure engine is running
        guard engine.isRunning else {
            try? engine.start()
            return
        }

        // Verify player is connected to engine
        guard fadePlayer.engine != nil else {
            print("❌ Fade player not connected to engine")
            return
        }

        let buffer = generateSineWave(frequency: 880.0, duration: 0.5)
        fadePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        fadePlayer.volume = Float(volume * 0.3)

        if !fadePlayer.isPlaying {
            fadePlayer.play()
        }
    }

    // MARK: - Audio Buffer Generators
    private func generateSineWave(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Generate for both channels (stereo)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (t / duration)
            let sample = Float(sin(2.0 * .pi * frequency * t) * envelope)
            channels[0][i] = sample // Left
            channels[1][i] = sample // Right
        }

        return buffer
    }

    private func generateNoise(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Generate noise for both channels (stereo)
        for i in 0..<Int(frameCount) {
            let sample = Float.random(in: -0.5...0.5)
            channels[0][i] = sample // Left
            channels[1][i] = sample // Right
        }

        return buffer
    }
}

// MARK: - ViewModel
class MagicalSwirlViewModel: ObservableObject {
    // MARK: - Settings
    @Published var fadeSpeed: Double = 5.0 // Range: 0.5 - 15.0 seconds
    @Published var trailThickness: Double = 5.0 // Range: 1.0 - 10.0
    @Published var glowStrength: Double = 0.5 // Range: 0.0 - 1.0
    @Published var colorMode: ColorMode = .random
    @Published var styleMode: StyleMode = .random
    @Published var isHapticsEnabled: Bool = true
    @Published var volume: Double = 0.5 // Range: 0.0 - 1.0

    // MARK: - Enums
    enum ColorMode: String, CaseIterable, Identifiable {
        case random = "Random"
        case single = "Single"
        case gradient = "Gradient"
        var id: String { self.rawValue }
    }

    enum StyleMode: String, CaseIterable, Identifiable {
        case random = "Random"
        case mist = "Mist"
        case neon = "Neon"
        case dust = "Dust"
        case ink = "Ink"
        case shimmer = "Shimmer"
        var id: String { self.rawValue }
    }

    // MARK: - Haptics
    private var hapticEngine: CHHapticEngine?

    init() {
        // Minimal init - no blocking operations
    }

    // MARK: - Audio Methods (Use Singleton)
    func prepareAudio() {
        // Access singleton to ensure it's initialized
        // This happens lazily on first access
        _ = SwirlAudioEngine.shared
    }

    func playTouchSound() {
        SwirlAudioEngine.shared.playTouchSound(volume: volume)
    }

    func playMoveSound(speed: Double) {
        SwirlAudioEngine.shared.playMoveSound(speed: speed, volume: volume)
    }

    func stopMoveSound() {
        SwirlAudioEngine.shared.stopMoveSound()
    }

    func playFadeSound() {
        SwirlAudioEngine.shared.playFadeSound(volume: volume)
    }

    // MARK: - Haptics
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic Error: \(error)")
        }
    }

    func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func triggerContinuousHaptic(intensity: Double) {
        guard isHapticsEnabled, let engine = hapticEngine else { return }

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityParam, sharpnessParam], relativeTime: 0, duration: 0.1)

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
}
