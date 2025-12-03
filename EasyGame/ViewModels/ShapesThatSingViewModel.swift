import Foundation
import Combine
import SwiftUI
import CoreGraphics

// MARK: - ViewModel
class ShapesThatSingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var shapes: [SingingShape] = []
    @Published var showMenu: Bool = false
    @Published var menuPosition: CGPoint = .zero
    @Published var isCollisionSoundEnabled: Bool = true
    @Published var showSettings: Bool = false
    @Published var volume: Double = 0.5 {
        didSet {
            // Update volume for all active players when slider changes
            ShapeAudioEngine.shared.updateVolume(volume)
        }
    }

    // Reference to scene (set by View)
    weak var scene: SingingShapeScene?

    // MARK: - Lifecycle
    init() {
        // Minimal init - prepare audio lazily
    }

    func prepareAudio() {
        // Access singleton to ensure it's initialized
        _ = ShapeAudioEngine.shared
    }

    func cleanup() {
        ShapeAudioEngine.shared.stopAll()
        shapes.removeAll()
    }

    // MARK: - Touch Handling (called by Scene)
    func handleTapOnEmptySpace(at location: CGPoint) {
        menuPosition = location
        showMenu = true
    }

    func handleShapeRemoved(id: UUID) {
        // Stop audio loop for this shape
        ShapeAudioEngine.shared.stopLoop(for: id)

        // Remove from our tracking
        shapes.removeAll { $0.id == id }
    }

    func handleCollision() {
        // Play collision sound if enabled
        if isCollisionSoundEnabled {
            ShapeAudioEngine.shared.playCollisionSound(volume: volume)
        }
    }

    // MARK: - Shape Management
    func addShape(_ type: ShapeType) {
        // Create shape model
        let shape = SingingShape(
            type: type,
            position: menuPosition
        )
        shapes.append(shape)

        // Add to scene
        scene?.addShape(id: shape.id, type: type, position: menuPosition)

        // Start audio loop
        ShapeAudioEngine.shared.startLoop(for: shape.id, type: type, volume: volume)

        // Close menu
        showMenu = false
    }

    func removeShape(id: UUID) {
        // Notify scene to animate removal
        scene?.removeShape(id: id)

        // Audio cleanup happens in handleShapeRemoved callback
    }

    func clearAll() {
        // Remove all shapes from scene
        scene?.removeAllShapes()

        // Stop all audio
        ShapeAudioEngine.shared.stopAll()

        // Clear our tracking
        shapes.removeAll()

        print("✓ Cleared all shapes")
    }
}
