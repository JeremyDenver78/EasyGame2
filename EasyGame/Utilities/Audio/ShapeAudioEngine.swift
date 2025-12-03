import Foundation
import AVFoundation

// MARK: - Audio Engine

class ShapeAudioEngine {
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let reverb = AVAudioUnitReverb()

    // We will use simple buffers for now since synthesizing DSP in Swift without C++ can be tricky/heavy.
    // However, we can create "impulse" buffers or use AVAudioUnitSampler if we had assets.
    // For a pure code solution, we'll use AVAudioSourceNode to generate waveforms.

    private var activeNodes: [UUID: AVAudioPlayerNode] = [:]
    private var activeBuffers: [UUID: AVAudioPCMBuffer] = [:]

    init() {
        mainMixer = engine.mainMixerNode

        // Setup Reverb for that "Ambient" feel
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 50

        engine.attach(reverb)
        engine.connect(reverb, to: mainMixer, format: nil)

        do {
            try engine.start()
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }

    func playSound(for shape: SingingShape) {
        // In a real app, we would load a nice sample.
        // Here, we will generate a simple buffer on the fly or use a basic oscillator.
        // For simplicity and stability in this demo, let's simulate the "idea" with a placeholder
        // or a very simple sine wave buffer.

        let frequency: Double
        switch shape.type {
        case .circle: frequency = 440.0 // A4
        case .triangle: frequency = 523.25 // C5
        case .square: frequency = 329.63 // E4
        case .hexagon: frequency = 392.00 // G4
        case .star: frequency = 587.33 // D5
        }

        let buffer = generateBuffer(frequency: frequency, duration: 2.0, type: shape.type)

        let player = AVAudioPlayerNode()
        engine.attach(player)
        // Connect to reverb
        engine.connect(player, to: reverb, format: buffer.format)

        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()

        // Fade in
        player.volume = 0
        // Animate volume? (AVAudioPlayerNode doesn't animate volume automatically, need a timer or ramp)
        player.volume = 0.5

        activeNodes[shape.id] = player
    }

    func stopSound(for id: UUID) {
        if let player = activeNodes[id] {
            player.stop()
            engine.detach(player)
            activeNodes.removeValue(forKey: id)
        }
    }

    func stopAll() {
        for (id, _) in activeNodes {
            stopSound(for: id)
        }
    }

    // Simple Waveform Generator
    private func generateBuffer(frequency: Double, duration: Double, type: ShapeType) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channels = buffer.floatChannelData!
        let data = channels[0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            // Envelope (Attack/Decay)
            let attack = 0.1
            let decay = duration - attack
            let envelope: Double
            if t < attack {
                envelope = t / attack
            } else {
                envelope = 1.0 - ((t - attack) / decay)
            }

            switch type {
            case .circle: // Sine (Bell-ish)
                sample = sin(2.0 * .pi * frequency * t)
            case .triangle: // Triangle wave (Chime-ish)
                let p = 2.0 * frequency * t
                sample = 2.0 * abs(2.0 * (p - floor(p + 0.5))) - 1.0
            case .square: // Square-ish (Pad) - actually let's use a low-passed saw or just sine with harmonics
                sample = sin(2.0 * .pi * frequency * t) + 0.5 * sin(2.0 * .pi * frequency * 2.0 * t)
            case .hexagon: // Pluck (dampened sine)
                sample = sin(2.0 * .pi * frequency * t) * exp(-3.0 * t)
            case .star: // FM-ish
                sample = sin(2.0 * .pi * frequency * t + sin(2.0 * .pi * 5.0 * t))
            }

            data[i] = Float(sample * envelope * 0.5) // 0.5 master volume
        }

        return buffer
    }
}
