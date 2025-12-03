import SwiftUI
import Combine
import AVFoundation
import CoreHaptics

// MARK: - Audio Engine
class SwirlAudioEngine {
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let reverb = AVAudioUnitReverb()

    // Nodes for different sounds
    private let touchPlayer = AVAudioPlayerNode()
    private let movePlayer = AVAudioPlayerNode()
    private let fadePlayer = AVAudioPlayerNode()

    private var isRunning = false

    init() {
        mainMixer = engine.mainMixerNode

        // Setup Reverb
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 40

        engine.attach(reverb)
        engine.connect(reverb, to: mainMixer, format: nil)

        // Setup Players
        setupPlayer(touchPlayer)
        setupPlayer(movePlayer)
        setupPlayer(fadePlayer)
    }

    func start() {
        guard !isRunning else { return }
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }

    private func setupPlayer(_ player: AVAudioPlayerNode) {
        engine.attach(player)
        // Use a standard stereo format for all connections
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
        engine.connect(player, to: reverb, format: format)
    }

    func playTouchSound(volume: Double) {
        guard isRunning else { return }
        let buffer = generateSineWave(frequency: 440.0, duration: 0.3)
        touchPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        touchPlayer.volume = Float(volume)
        if !touchPlayer.isPlaying {
            touchPlayer.play()
        }
    }

    func playMoveSound(speed: Double, volume: Double) {
        guard isRunning else { return }

        if !movePlayer.isPlaying {
            let buffer = generateNoise(duration: 1.0)
            movePlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            movePlayer.play()
        }

        movePlayer.volume = Float(min(1.0, speed / 1000.0) * volume * 0.5)
    }

    func stopMoveSound() {
        guard isRunning else { return }
        movePlayer.stop()
    }

    func playFadeSound(volume: Double) {
        guard isRunning else { return }
        let buffer = generateSineWave(frequency: 880.0, duration: 0.5)
        fadePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        fadePlayer.volume = Float(volume * 0.3)
        if !fadePlayer.isPlaying {
            fadePlayer.play()
        }
    }

    // Generators
    private func generateSineWave(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        // Use stereo format to match the audio engine setup
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Generate for both channels (stereo)
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (t / duration) // Simple decay
            let sample = Float(sin(2.0 * .pi * frequency * t) * envelope)
            channels[0][i] = sample // Left channel
            channels[1][i] = sample // Right channel
        }

        return buffer
    }

    private func generateNoise(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        // Use stereo format to match the audio engine setup
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!

        // Generate noise for both channels (stereo)
        for i in 0..<Int(frameCount) {
            let sample = Float.random(in: -0.5...0.5)
            channels[0][i] = sample // Left channel
            channels[1][i] = sample // Right channel
        }

        return buffer
    }
}

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

    // MARK: - Audio & Haptics
    private lazy var audio: SwirlAudioEngine = {
        let engine = SwirlAudioEngine()
        // Start audio engine on background thread to avoid blocking
        DispatchQueue.global(qos: .userInitiated).async {
            engine.start()
        }
        return engine
    }()

    private var hapticEngine: CHHapticEngine?

    init() {
        setupHaptics()
    }

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic Error: \(error)")
        }
    }

    func playTouchSound() {
        audio.playTouchSound(volume: volume)
    }

    func playMoveSound(speed: Double) {
        audio.playMoveSound(speed: speed, volume: volume)
    }

    func stopMoveSound() {
        audio.stopMoveSound()
    }

    func playFadeSound() {
        audio.playFadeSound(volume: volume)
    }

    // MARK: - Haptics
    func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func triggerContinuousHaptic(intensity: Double) {
        guard isHapticsEnabled, let engine = hapticEngine else { return }

        // Create a continuous haptic event
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
