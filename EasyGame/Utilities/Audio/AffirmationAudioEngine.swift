import Foundation
import AVFoundation

class AffirmationAudioEngine {
    static let shared = AffirmationAudioEngine()
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let reverb = AVAudioUnitReverb()
    private let pitch = AVAudioUnitTimePitch()
    private let audioQueue = DispatchQueue(label: "com.antigravity.affirmation.audio")
    
    private var currentPitchCents: Float = 0
    private var pitchWorkItem: DispatchWorkItem?
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        let mixer = engine.mainMixerNode
        
        // Reverb for spacey feel
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 50
        
        engine.attach(player)
        engine.attach(pitch)
        engine.attach(reverb)
        
        let format = mixer.outputFormat(forBus: 0)
        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: reverb, format: format)
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
    
    func nudgeUpForReveal() {
        // Subtle upward lift
        applyPitchOffset(cents: 16, rampIn: 1.2, hold: 1.2, rampOut: 2.4)
    }
    
    func nudgeDownForReturn() {
        // Gentle downward settle
        applyPitchOffset(cents: -14, rampIn: 1.2, hold: 1.0, rampOut: 2.4)
    }
    
    private func applyPitchOffset(cents: Float, rampIn: TimeInterval, hold: TimeInterval, rampOut: TimeInterval) {
        audioQueue.async { [weak self] in
            guard let self else { return }

            // Cancel any in-flight modulation
            self.pitchWorkItem?.cancel()

            var task: DispatchWorkItem!
            task = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.runPitchSequence(boundTo: task, target: cents, rampIn: rampIn, hold: hold, rampOut: rampOut)
            }

            self.pitchWorkItem = task
            self.audioQueue.async(execute: task)
        }
    }

    private func runPitchSequence(boundTo task: DispatchWorkItem, target: Float, rampIn: TimeInterval, hold: TimeInterval, rampOut: TimeInterval) {
        animatePitch(from: currentPitchCents, to: target, duration: rampIn, workItem: task) { [weak self] in
            guard let self else { return }

            // Hold at target
            self.audioQueue.asyncAfter(deadline: .now() + hold) { [weak self] in
                guard let self else { return }
                self.animatePitch(from: target, to: 0, duration: rampOut, workItem: task) { [weak self] in
                    self?.currentPitchCents = 0
                }
            }
        }
    }

    private func animatePitch(from start: Float, to end: Float, duration: TimeInterval, workItem: DispatchWorkItem, completion: (() -> Void)? = nil) {
        guard duration > 0 else {
            if !workItem.isCancelled, pitchWorkItem === workItem {
                pitch.pitch = end
                currentPitchCents = end
                completion?()
            }
            return
        }

        let steps = 32
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let value = start + (end - start) * Float(progress)
            let delay = stepDuration * Double(step)

            audioQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                guard self.pitchWorkItem === workItem, !workItem.isCancelled else { return }
                self.pitch.pitch = value
                self.currentPitchCents = value
                if step == steps {
                    completion?()
                }
            }
        }
    }
    
    func stop() {
        player.stop()
        engine.stop()
    }
}
