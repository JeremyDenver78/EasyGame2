import SpriteKit
import SwiftUI

class HarmonicBloomScene: SKScene {
    weak var viewModel: HarmonicBloomViewModel?

    private var particles: [BloomNode] = []
    private var lastAmplitude: Float = 0.0
    private var textureCache: SKTexture?

    // Config
    private let sensitivity: Float = 4.0
    private let splatThreshold: Float = 0.05 // Very sensitive to clicks

    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.scaleMode = .resizeFill
        view.allowsTransparency = false

        // Generate the "soft paint" texture once
        self.textureCache = createSoftTexture()
    }

    override func update(_ currentTime: TimeInterval) {
        guard let viewModel = viewModel else { return }

        let rawAmp = viewModel.currentAmplitude
        let currentAmp = rawAmp * sensitivity
        let frequencies = viewModel.frequencyData

        let delta = currentAmp - lastAmplitude

        // 1. SPLAT (Clicks/Snaps)
        // Lower threshold to catch finger snaps
        if delta > splatThreshold {
            let x = CGFloat.random(in: 50...(size.width - 50))
            let y = CGFloat.random(in: 50...(size.height - 50))
            let color = getColor(from: frequencies)

            // Intensity dictates size and count
            spawnSplat(at: CGPoint(x: x, y: y), intensity: CGFloat(currentAmp), color: color)
        }

        // 2. HUM (Sustained sound)
        // If volume is consistent, paint trails
        if currentAmp > 0.1 {
            let spawnCount = Int(currentAmp * 3) // Fewer particles than before for elegance
            for _ in 0..<spawnCount {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let color = getColor(from: frequencies)

                spawnTrail(at: CGPoint(x: x, y: y), intensity: CGFloat(currentAmp), color: color)
            }
        }

        // 3. Update Particles (Physics & Fade)
        for (index, particle) in particles.enumerated().reversed() {
            particle.update()

            if particle.alpha <= 0 {
                particle.removeFromParent()
                particles.remove(at: index)
            }
        }

        // Smooth amplitude tracking
        lastAmplitude = lerp(start: lastAmplitude, end: currentAmp, t: 0.15)
    }

    // MARK: - Spawning

    private func spawnSplat(at position: CGPoint, intensity: CGFloat, color: UIColor) {
        let count = Int.random(in: 5...12)

        for _ in 0..<count {
            guard let texture = textureCache else { return }

            let scale = CGFloat.random(in: 0.2...0.8) * intensity
            let node = SKSpriteNode(texture: texture)
            node.position = position
            node.color = color
            node.colorBlendFactor = 1.0 // Use the color fully
            node.blendMode = .add
            node.setScale(0) // Start invisible

            // Animate pop-in
            let popIn = SKAction.scale(to: scale, duration: 0.1)
            node.run(popIn)

            // "Flick" physics
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 5...12) * intensity // Initial burst
            let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)

            let particle = BloomNode(node: node, velocity: velocity, type: .splat)
            addChild(node)
            particles.append(particle)
        }
    }

    private func spawnTrail(at position: CGPoint, intensity: CGFloat, color: UIColor) {
        guard let texture = textureCache else { return }

        let node = SKSpriteNode(texture: texture)
        node.position = position
        node.color = color.withAlphaComponent(0.6)
        node.colorBlendFactor = 1.0
        node.blendMode = .add
        node.setScale(CGFloat.random(in: 0.1...0.3) * intensity)

        // Gentle drift
        let speed = CGFloat.random(in: 1...3)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)

        let particle = BloomNode(node: node, velocity: velocity, type: .trail)
        addChild(node)
        particles.append(particle)
    }

    // MARK: - Utilities

    private func createSoftTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let ctx = context.cgContext
            // Soft Radial Gradient
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0] // Center to Edge
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }

            ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 32, y: 32), startRadius: 0, endCenter: CGPoint(x: 32, y: 32), endRadius: 32, options: [])
        }

        return SKTexture(image: image)
    }

    private func getColor(from frequencies: [Float]) -> UIColor {
        // Find dominant frequency
        var peakIndex = 0
        var peakValue: Float = 0
        for i in stride(from: 0, to: min(frequencies.count, 60), by: 3) {
            if frequencies[i] > peakValue {
                peakValue = frequencies[i]
                peakIndex = i
            }
        }

        let hue = CGFloat(peakIndex) / 60.0
        let variedHue = (hue + CGFloat.random(in: -0.05...0.05)).truncatingRemainder(dividingBy: 1.0)
        // High saturation, lower brightness for "elegant" look
        return UIColor(hue: variedHue, saturation: 0.7, brightness: 0.9, alpha: 1.0)
    }

    private func lerp(start: Float, end: Float, t: Float) -> Float {
        return start + (end - start) * t
    }
}

// MARK: - Particle Logic
class BloomNode {
    let node: SKSpriteNode
    var velocity: CGVector
    var alpha: CGFloat = 1.0
    let type: ParticleType

    enum ParticleType {
        case splat
        case trail
    }

    init(node: SKSpriteNode, velocity: CGVector, type: ParticleType) {
        self.node = node
        self.velocity = velocity
        self.type = type
    }

    func update() {
        // Apply Velocity
        node.position.x += velocity.dx
        node.position.y += velocity.dy

        // PHYSICS: Friction / Damping
        // This is the key to the "Paint" feel.
        // Instead of flying forever, they slow down and stop.
        velocity.dx *= 0.92
        velocity.dy *= 0.92

        // FADE: Very slow decay
        // Allows particles to accumulate on screen
        switch type {
        case .splat:
            alpha -= 0.005 // Lingers for ~3 seconds
        case .trail:
            alpha -= 0.008
        }

        node.alpha = alpha
    }

    func removeFromParent() {
        node.removeFromParent()
    }
}
