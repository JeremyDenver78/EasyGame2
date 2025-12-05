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
    private let launchPlayer = AVAudioPlayerNode()

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
        engine.attach(launchPlayer)

        // 2. Connect nodes in proper order: Player -> Mixer -> Output
        // Use stereo format (2 channels) for all connections
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            print("❌ Audio Graph setup failed: format unavailable")
            return
        }

        engine.connect(touchPlayer, to: mainMixer, format: format)
        engine.connect(movePlayer, to: mainMixer, format: format)
        engine.connect(fadePlayer, to: mainMixer, format: format)
        engine.connect(launchPlayer, to: mainMixer, format: format)
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
    func playLaunchSound() {
        if !engine.isRunning {
            try? engine.start()
        }

        if launchPlayer.engine == nil {
            let format = mainMixer.outputFormat(forBus: 0)
            engine.attach(launchPlayer)
            engine.connect(launchPlayer, to: mainMixer, format: format)
        }

        guard let buffer = generateAppLaunch() else { return }

        launchPlayer.stop()
        launchPlayer.reset()
        launchPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        launchPlayer.volume = 0.35

        if !launchPlayer.isPlaying {
            launchPlayer.play()
        }
    }

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

        guard let buffer = generateSineWave(frequency: 440.0, duration: 0.3) else { return }
        touchPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        touchPlayer.volume = Float(volume * 0.6) // soften beeps

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
            guard let buffer = generateNoise(duration: 1.0) else { return }
            movePlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            movePlayer.play()
        }

        movePlayer.volume = Float(min(1.0, speed / 1000.0) * volume * 0.1) // ~80% softer
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

        guard let buffer = generateSineWave(frequency: 880.0, duration: 0.5) else { return }
        fadePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        fadePlayer.volume = Float(volume * 0.18) // gentler fades

        if !fadePlayer.isPlaying {
            fadePlayer.play()
        }
    }

    // MARK: - Audio Buffer Generators
    private func generateAppLaunch(frequency: Double = 224, duration: Double = 5.0) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            print("❌ App launch format unavailable")
            return nil
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to allocate app launch buffer")
            return nil
        }
        buffer.frameLength = frameCount
        guard let channels = buffer.floatChannelData else {
            print("❌ App launch channels unavailable")
            return nil
        }

        // ADSR Parameters
        let attackTime = 0.79
        let decayTime = 0.3
        let sustainLevel = 0.2
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let phase = 2.0 * .pi * frequency * t

            let sample = sin(phase)

            // ADSR Envelope
            let cycleTime = t.truncatingRemainder(dividingBy: duration)
            var env = 0.0
            if cycleTime < attackTime {
                env = cycleTime / attackTime
            } else if cycleTime < (attackTime + decayTime) {
                let decayProgress = (cycleTime - attackTime) / decayTime
                env = 1.0 + (sustainLevel - 1.0) * decayProgress
            } else {
                // Release tail to gently fade out by the end of the buffer
                let releaseProgress = min(1.0, (cycleTime - (attackTime + decayTime)) / 2.01)
                env = sustainLevel * (1.0 - releaseProgress)
            }

            let finalSample = Float(sample * env * 0.5)
            channels[0][i] = finalSample
            channels[1][i] = finalSample
        }
        return buffer
    }

    private func generateSineWave(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            print("❌ Sine wave format unavailable")
            return nil
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to allocate sine wave buffer")
            return nil
        }
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else {
            print("❌ Sine wave channels unavailable")
            return nil
        }

        let attack = min(0.04, duration * 0.35)
        let releaseStart = duration * 0.45

        // Generate for both channels (stereo)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let base = sin(2.0 * .pi * frequency * t)

            let env: Double
            if t < attack {
                env = t / attack
            } else if t > releaseStart {
                let releaseDur = max(0.001, duration - releaseStart)
                env = max(0.0, (duration - t) / releaseDur)
            } else {
                env = 1.0
            }

            let sample = Float(base * env * 0.6)
            channels[0][i] = sample // Left
            channels[1][i] = sample // Right
        }

        return buffer
    }

    private func generateNoise(duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            print("❌ Noise format unavailable")
            return nil
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to allocate noise buffer")
            return nil
        }
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else {
            print("❌ Noise channels unavailable")
            return nil
        }

        var smooth: Float = 0.0
        let smoothing: Float = 0.92

        // Generate softened noise for both channels (stereo)
        for i in 0..<Int(frameCount) {
            let raw = Float.random(in: -0.3...0.3)
            smooth = smoothing * smooth + (1 - smoothing) * raw
            channels[0][i] = smooth // Left
            channels[1][i] = smooth // Right
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
    @Published var hasCreatedFirstSwirl: Bool = false // Track first touch

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
