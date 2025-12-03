import SpriteKit
import SwiftUI

class HarmonicBloomScene: SKScene {
    // MARK: - Properties
    weak var viewModel: HarmonicBloomViewModel?

    // Track active particles
    private var particles: [BloomNode] = []

    // Audio tracking
    private var lastAmplitude: Float = 0.0
    private let sensitivity: Float = 3.5 // Multiplier to make it react easier

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .resizeFill
        view.allowsTransparency = false

        // No initial spawn - Start Empty
    }

    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        guard let viewModel = viewModel else { return }

        let rawAmp = viewModel.currentAmplitude
        let currentAmp = rawAmp * sensitivity
        let frequencies = viewModel.frequencyData

        // 1. Detect Audio Events
        let delta = currentAmp - lastAmplitude

        // A. DETECT "SPLAT" (Sharp rise in volume - Clap/Drum)
        if delta > 0.15 {
            // Spawn a burst at a random location
            let x = CGFloat.random(in: 50...(size.width - 50))
            let y = CGFloat.random(in: 50...(size.height - 50))
            let color = getColor(from: frequencies)

            spawnSplat(at: CGPoint(x: x, y: y), intensity: CGFloat(currentAmp), color: color)
        }

        // B. DETECT "HUM/TRAIL" (Sustained volume)
        if currentAmp > 0.1 {
            // Spawn trails randomly across the screen
            // The louder it is, the more trails we spawn per frame
            let spawnCount = Int(currentAmp * 5)
            for _ in 0..<spawnCount {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let color = getColor(from: frequencies)

                spawnTrail(at: CGPoint(x: x, y: y), intensity: CGFloat(currentAmp), color: color)
            }
        }

        // 2. Update Particles
        // We iterate backwards so we can remove dead particles safely
        for (index, particle) in particles.enumerated().reversed() {
            particle.update()

            if particle.alpha <= 0 {
                particle.removeFromParent()
                particles.remove(at: index)
            }
        }

        // Save state for next frame
        lastAmplitude = lerp(start: lastAmplitude, end: currentAmp, t: 0.1)
    }

    // MARK: - Spawning Logic

    private func spawnSplat(at position: CGPoint, intensity: CGFloat, color: UIColor) {
        let count = Int.random(in: 8...15)

        for _ in 0..<count {
            let node = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6) * intensity)
            node.position = position
            node.fillColor = color
            node.strokeColor = .clear
            node.blendMode = .add // Makes overlapping colors glow

            // Random explosion velocity
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 5...15) * intensity
            let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)

            let particle = BloomNode(node: node, velocity: velocity, type: .splat)
            addChild(node)
            particles.append(particle)
        }
    }

    private func spawnTrail(at position: CGPoint, intensity: CGFloat, color: UIColor) {
        // Trails are elongated or small fast dots
        let node = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3) * intensity)
        node.position = position
        node.fillColor = color.withAlphaComponent(0.8)
        node.strokeColor = .clear
        node.blendMode = .add

        // Direction depends on position (e.g., flow towards center, or random flow)
        // Let's make them flow in random linear directions for "shooting star" feel
        let speed = CGFloat.random(in: 3...8) * intensity
        // Bias direction slightly upwards/rightwards for positive feel, or totally random
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)

        let particle = BloomNode(node: node, velocity: velocity, type: .trail)
        addChild(node)
        particles.append(particle)
    }

    // MARK: - Helpers

    private func getColor(from frequencies: [Float]) -> UIColor {
        // Map strongest frequency to color
        // Find peak frequency index
        var peakIndex = 0
        var peakValue: Float = 0

        // Sample a few bands to save performance
        for i in stride(from: 0, to: min(frequencies.count, 50), by: 2) {
            if frequencies[i] > peakValue {
                peakValue = frequencies[i]
                peakIndex = i
            }
        }

        // Map index to Hue
        let hue = CGFloat(peakIndex) / 50.0
        // Add some random variation so it's not monotone
        let variedHue = (hue + CGFloat.random(in: -0.1...0.1)).truncatingRemainder(dividingBy: 1.0)

        return UIColor(hue: variedHue, saturation: 0.8, brightness: 1.0, alpha: 1.0)
    }

    private func lerp(start: Float, end: Float, t: Float) -> Float {
        return start + (end - start) * t
    }
}

// MARK: - Custom Node Class
class BloomNode {
    let node: SKShapeNode
    var velocity: CGVector
    var alpha: CGFloat = 1.0
    let type: ParticleType

    enum ParticleType {
        case splat
        case trail
    }

    init(node: SKShapeNode, velocity: CGVector, type: ParticleType) {
        self.node = node
        self.velocity = velocity
        self.type = type
    }

    func update() {
        // Move
        node.position.x += velocity.dx
        node.position.y += velocity.dy

        // Behavior based on type
        switch type {
        case .splat:
            // Splats slow down quickly (friction) and fade fast
            velocity.dx *= 0.92
            velocity.dy *= 0.92
            alpha -= 0.02

        case .trail:
            // Trails keep speed but fade slowly
            // Optional: "Stretch" effect based on velocity
            if abs(velocity.dx) > 1 || abs(velocity.dy) > 1 {
                node.xScale = 1 + (abs(velocity.dx) * 0.1)
                node.yScale = 1 - (abs(velocity.dx) * 0.05)
                node.zRotation = atan2(velocity.dy, velocity.dx)
            }
            alpha -= 0.01 // Slower fade
        }

        // Apply Alpha
        node.alpha = alpha
    }

    func removeFromParent() {
        node.removeFromParent()
    }
}
