import Foundation
import SwiftUI

class AffirmationOrbViewModel: ObservableObject {
    enum OrbState {
        case sphere
        case morphingToText
        case reading
        case morphingToSphere
    }
    
    @Published var state: OrbState = .sphere
    @Published var currentAffirmation: String = ""
    @Published var buttonText: String = "Reveal Affirmation"
    @Published var isButtonDisabled: Bool = false
    
    // Reference to Scene
    weak var scene: AffirmationOrbScene?
    
    func onAppear() {
        AffirmationAudioEngine.shared.startDrone()
    }
    
    func onDisappear() {
        AffirmationAudioEngine.shared.stop()
    }
    
    func handleButtonPress() {
        if state == .sphere {
            // Pick random affirmation
            let text = AffirmationData.list.randomElement() ?? "I am calm"
            currentAffirmation = text
            
            // Trigger Animation
            state = .morphingToText
            isButtonDisabled = true
            buttonText = "..."
            
            scene?.morphToText(text) { [weak self] in
                // Animation complete
                guard let self else { return }
                self.state = .reading
                self.buttonText = "Return to Orb"
                self.isButtonDisabled = false

                // Hold for a beat, then auto-return to orb
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    self?.autoReturnToOrb()
                }
            }
        } else if state == .reading {
            // Return to sphere
            autoReturnToOrb()
        }
    }

    private func autoReturnToOrb() {
        guard state == .reading else { return }
        state = .morphingToSphere
        isButtonDisabled = true
        buttonText = "..."

        scene?.morphToSphere { [weak self] in
            guard let self else { return }
            self.state = .sphere
            self.buttonText = "Reveal Affirmation"
            self.isButtonDisabled = false
        }
    }
}
