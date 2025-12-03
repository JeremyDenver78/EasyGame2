import SpriteKit
import SwiftUI

class HarmonicBloomScene: SKScene {
    // Reference to ViewModel for data
    weak var viewModel: HarmonicBloomViewModel?

    private var particles: [BloomParticle] = []
    private let numParticles = 130 // Good balance of density and performance

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .resizeFill
        view.allowsTransparency = false

        spawnParticles()
    }

    private func spawnParticles() {
        self.removeAllChildren()
        particles.removeAll()

        for _ in 0..<numParticles {
            let particle = BloomParticle()

            // Random Position
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            particle.node.position = CGPoint(x: x, y: y)

            // Random Drift Velocity
            particle.velocity = CGVector(
                dx: CGFloat.random(in: -1.5...1.5),
                dy: CGFloat.random(in: -1.5...1.5)
            )

            // Random Base Size
            particle.baseRadius = CGFloat.random(in: 3...8)

            addChild(particle.node)
            particles.append(particle)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard let viewModel = viewModel else { return }

        let frequencies = viewModel.frequencyData
        let amplitude = CGFloat(viewModel.currentAmplitude)

        for particle in particles {
            let node = particle.node

            // 1. PHYSICS: Move & Bounce
            node.position.x += particle.velocity.dx
            node.position.y += particle.velocity.dy

            // Bounce off edges
            if node.position.x < 0 || node.position.x > size.width { particle.velocity.dx *= -1 }
            if node.position.y < 0 || node.position.y > size.height { particle.velocity.dy *= -1 }

            // 2. AUDIO MAPPING: Frequency based on X position
            // Map X position (0.0 - 1.0) to Frequency Index (0 - 255)
            let relativeX = node.position.x / size.width
            let freqIndex = Int(relativeX * CGFloat(frequencies.count - 1))
            // Safety clamp
            let safeIndex = max(0, min(frequencies.count - 1, freqIndex))

            let audioValue = CGFloat(frequencies[safeIndex]) // 0.0 (silent) to 1.0 (loud)

            // 3. VISUALS: React to sound

            // SIZE: Base + (Audio Frequency * Factor) + (Global Volume * Factor)
            let targetRadius = particle.baseRadius + (audioValue * 60.0) + (amplitude * 15.0)

            // Smooth resizing (Linear Interpolation)
            particle.currentRadius = particle.currentRadius + (targetRadius - particle.currentRadius) * 0.2
            node.setScale(particle.currentRadius / 10.0) // Normalize scale

            // COLOR: Cycle Hue based on position + intensity
            let hue = (relativeX + (audioValue * 0.3)).truncatingRemainder(dividingBy: 1.0)
            let saturation: CGFloat = 0.8
            let brightness: CGFloat = 0.4 + (audioValue * 0.6) // Get brighter when loud

            if let shape = node as? SKShapeNode {
                shape.fillColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 0.8)
                // Glow stroke
                shape.strokeColor = shape.fillColor.withAlphaComponent(0.4)
                shape.lineWidth = audioValue * 5.0
            }
        }
    }
}

// Helper Class
class BloomParticle {
    let node: SKShapeNode
    var velocity: CGVector = .zero
    var baseRadius: CGFloat = 0
    var currentRadius: CGFloat = 0

    init() {
        // Create circle shape (radius 10 for better resolution, we scale it down)
        node = SKShapeNode(circleOfRadius: 10.0)
        node.lineWidth = 0
        node.fillColor = .white
    }
}
