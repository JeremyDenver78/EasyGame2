import Foundation
import AVFoundation

class AffirmationAudioEngine {
    static let shared = AffirmationAudioEngine()
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let reverb = AVAudioUnitReverb()
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        let mixer = engine.mainMixerNode
        
        // Reverb for spacey feel
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 50
        
        engine.attach(player)
        engine.attach(reverb)
        
        let format = mixer.outputFormat(forBus: 0)
        engine.connect(player, to: reverb, format: format)
        engine.connect(reverb, to: mixer, format: format)
    }
    
    func startDrone() {
        guard !engine.isRunning else { return }
        try? engine.start()
        
        // Generate a soft sine drone (A3 - 220Hz)
        let sampleRate = 44100.0
        let duration = 5.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        let channels = buffer.floatChannelData!
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let val = Float(sin(2.0 * .pi * 220.0 * t)) * 0.1
            channels[0][i] = val
            channels[1][i] = val
        }
        
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        player.stop()
        engine.stop()
    }
}
