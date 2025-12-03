import Foundation
import Combine
import SwiftUI
import CoreGraphics

// MARK: - ViewModel

class ShapesThatSingViewModel: ObservableObject {
    @Published var shapes: [SingingShape] = []
    @Published var showMenu: Bool = false
    @Published var menuPosition: CGPoint = .zero

    private let audio = ShapeAudioEngine()
    private var timer: Timer?
    private var screenSize: CGSize = .zero

    func start(screenSize: CGSize) {
        self.screenSize = screenSize

        // Start Loop
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        audio.stopAll()
    }

    func handleTap(at location: CGPoint) {
        // Check if tapped existing shape
        if let index = shapes.firstIndex(where: { distance($0.position, location) < 50 }) {
            // Remove shape
            let shape = shapes[index]
            audio.stopSound(for: shape.id)
            shapes.remove(at: index)
        } else {
            // Open menu
            menuPosition = location
            showMenu = true
        }
    }

    func addShape(_ type: ShapeType) {
        let shape = SingingShape(
            type: type,
            position: menuPosition,
            driftVelocity: CGPoint(
                x: CGFloat.random(in: -0.5...0.5),
                y: CGFloat.random(in: -0.5...0.5)
            )
        )
        shapes.append(shape)

        // Start Sound
        audio.playSound(for: shape)

        // Animate in
        withAnimation(.spring()) {
            if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
                shapes[index].scale = 1.0
            }
        }

        showMenu = false
    }

    func clearAll() {
        audio.stopAll()
        withAnimation {
            shapes.removeAll()
        }
    }

    private func update() {
        for i in 0..<shapes.count {
            // Drift
            shapes[i].position.x += shapes[i].driftVelocity.x
            shapes[i].position.y += shapes[i].driftVelocity.y

            // Rotate
            shapes[i].rotation += 0.2

            // Pulse Brightness (Visualizing the loop)
            let time = Date().timeIntervalSince1970
            let loopDuration = shapes[i].type.loopDuration
            let progress = (time.truncatingRemainder(dividingBy: loopDuration)) / loopDuration

            // Pulse on the "beat" (start of loop)
            if progress < 0.1 {
                shapes[i].brightness = 1.0 - (progress * 5.0) // Flash
            } else {
                shapes[i].brightness = 0.5 + sin(time) * 0.1 // Gentle breathe
            }

            // Bounce off walls
            if shapes[i].position.x < 0 || shapes[i].position.x > screenSize.width {
                shapes[i].driftVelocity.x *= -1
            }
            if shapes[i].position.y < 0 || shapes[i].position.y > screenSize.height {
                shapes[i].driftVelocity.y *= -1
            }
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return hypot(a.x - b.x, a.y - b.y)
    }
}
