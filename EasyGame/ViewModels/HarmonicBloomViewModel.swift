import Foundation
import AVFoundation
import SwiftUI

class HarmonicBloomViewModel: ObservableObject {
    @Published var hasMicrophoneAccess: Bool = false
    @Published var permissionDenied: Bool = false

    // Connect to the processor
    private let audioProcessor = AudioSpectrumProcessor.shared

    // Computed properties for the Scene to read directly
    var frequencyData: [Float] {
        return audioProcessor.frequencyData
    }

    var currentAmplitude: Float {
        return audioProcessor.amplitude
    }

    func checkPermissions() {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            self.hasMicrophoneAccess = true
            self.startAudio()
        case .denied:
            self.permissionDenied = true
        case .undetermined:
            requestPermission()
        @unknown default:
            break
        }
    }

    private func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.hasMicrophoneAccess = true
                    self?.startAudio()
                } else {
                    self?.permissionDenied = true
                }
            }
        }
    }

    private func startAudio() {
        do {
            // Configure session for playback and recording
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            audioProcessor.start()
        } catch {
            print("Audio Session Error: \(error)")
        }
    }

    func stopAudio() {
        audioProcessor.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
