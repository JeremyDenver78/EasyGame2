import SpriteKit
import SwiftUI

class MagicalSwirlScene: SKScene {
    // MARK: - Properties
    weak var viewModel: MagicalSwirlViewModel?

    private var activeTrails: [UITouch: SKEmitterNode] = [:]
    private var touchVelocities: [UITouch: CGFloat] = [:]
    private var lastTouchPositions: [UITouch: (point: CGPoint, time: TimeInterval)] = [:]

    // MARK: - Texture Cache (Critical for Performance)
    // Textures are generated ONCE and reused for all emitters
    private var textureCache: [String: SKTexture] = [:]

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        view.allowsTransparency = true
        view.isMultipleTouchEnabled = true

        // Pre-generate and cache all textures ONCE
        initializeTextureCache()
    }

    private func initializeTextureCache() {
        // Generate standard particle texture (sharp gradient)
        textureCache["standard"] = createParticleTexture()

        // Generate soft/mist texture (diffuse cloud)
        textureCache["soft"] = createSoftTexture()

        print("✓ Texture cache initialized with \(textureCache.count) textures")
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let viewModel = viewModel else { return }

        // Mark first swirl created (hides instructions)
        if !viewModel.hasCreatedFirstSwirl {
            viewModel.hasCreatedFirstSwirl = true
        }

        for touch in touches {
            let location = touch.location(in: self)
            createTrail(at: location, for: touch)

            // Initialize tracking
            lastTouchPositions[touch] = (location, Date().timeIntervalSince1970)
            touchVelocities[touch] = 0

            // Haptics and Sound
            viewModel.triggerHaptic(style: .light)
            viewModel.playTouchSound()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let viewModel = viewModel else { return }

        for touch in touches {
            let location = touch.location(in: self)

            // Calculate Speed
            if let lastData = lastTouchPositions[touch] {
                let currentTime = Date().timeIntervalSince1970
                let dt = CGFloat(currentTime - lastData.time)
                let dx = location.x - lastData.point.x
                let dy = location.y - lastData.point.y
                let distance = sqrt(dx*dx + dy*dy)

                if dt > 0 {
                    let speed = distance / dt
                    touchVelocities[touch] = speed

                    // Dynamic Feedback
                    viewModel.playMoveSound(speed: Double(speed))
                    if speed > 500 { // Threshold for haptics
                        viewModel.triggerContinuousHaptic(intensity: min(1.0, Double(speed) / 2000.0))
                    }
                }

                lastTouchPositions[touch] = (location, currentTime)
            }

            // Update emitter position
            if let emitter = activeTrails[touch] {
                emitter.position = location

                // Dynamic Visuals based on speed
                let speed = touchVelocities[touch] ?? 0
                if speed > 100 {
                    // Faster movement = more dramatic effect
                    let speedFactor = min(speed / 1000.0, 2.0)
                    emitter.particleBirthRate = 100 * CGFloat(viewModel.trailThickness) * speedFactor
                    emitter.particleScale = 0.2 * CGFloat(viewModel.trailThickness) / 5.0 * (1.0 + speedFactor * 0.3)
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchesEnded(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchesEnded(touches)
    }

    private func handleTouchesEnded(_ touches: Set<UITouch>) {
        guard let viewModel = viewModel else { return }

        for touch in touches {
            if let emitter = activeTrails[touch] {
                // CRITICAL: Stop emitting new particles immediately
                // BUT keep existing particles alive to fade naturally
                emitter.particleBirthRate = 0

                // Remove from active tracking
                activeTrails.removeValue(forKey: touch)
                lastTouchPositions.removeValue(forKey: touch)
                touchVelocities.removeValue(forKey: touch)

                // Calculate fade-out duration based on particle lifetime
                // Particles will continue to exist and fade according to their lifetime settings
                let lifetime = TimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange / 2)

                // Schedule cleanup AFTER all particles have naturally died
                // This creates the "lingering trail" effect based on fadeSpeed setting
                let cleanupAction = SKAction.sequence([
                    SKAction.wait(forDuration: lifetime),
                    SKAction.removeFromParent()
                ])
                emitter.run(cleanupAction)

                // Haptics and Sound
                viewModel.triggerHaptic(style: .light)
                viewModel.playFadeSound()
                viewModel.stopMoveSound()
            }
        }
    }

    // MARK: - Trail Creation
    private func createTrail(at position: CGPoint, for touch: UITouch) {
        guard let viewModel = viewModel else { return }

        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.targetNode = self

        // Configure based on current settings from ViewModel
        configureEmitter(emitter, with: viewModel)

        addChild(emitter)
        activeTrails[touch] = emitter
    }

    private func configureEmitter(_ emitter: SKEmitterNode, with viewModel: MagicalSwirlViewModel) {
        // Get the appropriate style mode (handle random)
        let actualStyle = viewModel.styleMode == .random
            ? MagicalSwirlViewModel.StyleMode.allCases.filter { $0 != .random }.randomElement() ?? .mist
            : viewModel.styleMode

        // Select texture from cache based on style (NO generation here!)
        let textureKey: String
        switch actualStyle {
        case .mist, .ink, .dust:
            textureKey = "soft"
        default:
            textureKey = "standard"
        }

        // Use cached texture - this is critical for performance
        emitter.particleTexture = textureCache[textureKey] ?? textureCache["standard"]

        // Basic particle settings (responsive to fadeSpeed and trailThickness)
        emitter.particleBirthRate = 100 * CGFloat(viewModel.trailThickness)
        emitter.particleLifetime = CGFloat(viewModel.fadeSpeed)
        emitter.particleLifetimeRange = CGFloat(viewModel.fadeSpeed) * 0.3
        emitter.particlePositionRange = CGVector(dx: 5, dy: 5)
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.8 / CGFloat(viewModel.fadeSpeed)
        emitter.particleScale = 0.2 * CGFloat(viewModel.trailThickness) / 5.0
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.05
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2

        // Color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = getColor(mode: viewModel.colorMode)

        // Style-specific adjustments
        switch actualStyle {
        case .mist:
            emitter.particleSpeed = 10
            emitter.particlePositionRange = CGVector(dx: 15, dy: 15)
            emitter.particleAlpha = 0.4
            emitter.particleBlendMode = .alpha

        case .neon:
            emitter.particleBlendMode = .add
            emitter.particleScale = 0.15 * CGFloat(viewModel.trailThickness) / 5.0
            emitter.particleBirthRate *= 1.5
            emitter.particleColorBlendFactor = 1.0
            emitter.particleAlpha = 0.9

        case .dust:
            emitter.particleScale = 0.05 * CGFloat(viewModel.trailThickness) / 5.0
            emitter.particleBirthRate *= 2.0
            emitter.particleSpeed = 5
            emitter.particleAlpha = 0.6
            emitter.particleBlendMode = .alpha

        case .ink:
            emitter.particleAlphaSpeed = -0.2 / CGFloat(viewModel.fadeSpeed)
            emitter.particleScaleSpeed = 0.1
            emitter.particleBlendMode = .alpha
            emitter.particleAlpha = 0.5

        case .shimmer:
            emitter.particleBlendMode = .add
            emitter.particleRotation = 0
            emitter.particleRotationRange = .pi * 2
            emitter.particleRotationSpeed = 2.0
            emitter.particleScaleRange = 0.2
            emitter.particleAlpha = 0.7

        case .random:
            // This case is handled above, should never reach here
            break
        }

        // Apply glow strength
        if viewModel.glowStrength > 0 {
            emitter.particleBlendMode = .add
            let glowBoost = 0.3 * CGFloat(viewModel.glowStrength)
            emitter.particleAlpha = min(1.0, emitter.particleAlpha + glowBoost)
        }
    }

    private func getColor(mode: MagicalSwirlViewModel.ColorMode) -> UIColor {
        switch mode {
        case .single:
            return UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0) // Cyan

        case .random:
            // Calming palette
            let palettes: [UIColor] = [
                UIColor(red: 0.68, green: 0.85, blue: 0.90, alpha: 1.0), // Powder Blue
                UIColor(red: 0.40, green: 0.80, blue: 0.85, alpha: 1.0), // Teal
                UIColor(red: 0.85, green: 0.70, blue: 0.95, alpha: 1.0), // Lavender
                UIColor(red: 0.95, green: 0.75, blue: 0.80, alpha: 1.0), // Soft Pink
                UIColor(red: 1.00, green: 0.85, blue: 0.60, alpha: 1.0)  // Warm Amber
            ]
            return palettes.randomElement() ?? .white

        case .gradient:
            // Time-based color cycling
            let time = Date().timeIntervalSince1970
            let hue = CGFloat(time.remainder(dividingBy: 10) / 10)
            return UIColor(hue: hue, saturation: 0.6, brightness: 0.9, alpha: 1.0)
        }
    }

    // MARK: - Texture Generation (Called ONCE on initialization)
    private func createParticleTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let ctx = context.cgContext

            // Radial gradient for smooth particle
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let locations: [CGFloat] = [0.2, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }

            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 32, y: 32),
                startRadius: 0,
                endCenter: CGPoint(x: 32, y: 32),
                endRadius: 32,
                options: []
            )
        }

        return SKTexture(image: image)
    }

    private func createSoftTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let ctx = context.cgContext

            // Very soft, diffuse cloud
            let colors = [
                UIColor.white.withAlphaComponent(0.8).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }

            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 32, y: 32),
                startRadius: 0,
                endCenter: CGPoint(x: 32, y: 32),
                endRadius: 32,
                options: []
            )
        }

        return SKTexture(image: image)
    }
}
