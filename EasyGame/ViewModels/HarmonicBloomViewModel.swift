import Foundation
import AVFoundation
import Combine

class HarmonicBloomViewModel: ObservableObject {
    @Published var hasMicrophoneAccess: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var contentMissing: Bool = false

    func checkPermissions() {
        // First check if the www folder exists
        if Bundle.main.url(forResource: "www", withExtension: nil) == nil {
            self.contentMissing = true
            return
        }

        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            self.hasMicrophoneAccess = true
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
                } else {
                    self?.permissionDenied = true
                }
            }
        }
    }
}
