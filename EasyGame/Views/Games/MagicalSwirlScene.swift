import SpriteKit
import SwiftUI

class MagicalSwirlScene: SKScene {
    // MARK: - Properties
    var viewModel: MagicalSwirlViewModel?
    
    private var activeTrails: [UITouch: SKEmitterNode] = [:]
    private var touchVelocities: [UITouch: CGFloat] = [:]
    private var lastTouchPositions: [UITouch: (point: CGPoint, time: TimeInterval)] = [:]
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        view.allowsTransparency = true
        view.isMultipleTouchEnabled = true
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let viewModel = viewModel else { return }
        
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
            
            if let emitter = activeTrails[touch] {
                emitter.position = location
                
                // Dynamic Visuals based on speed
                let speed = touchVelocities[touch] ?? 0
                if speed > 100 {
                    emitter.particleScaleSpeed = -0.05 + (speed / 5000.0) // Grow slightly if fast
                    emitter.particleLifetime = CGFloat(viewModel.fadeSpeed) * (1.0 + speed / 2000.0) // Linger longer
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
                // Stop emitting new particles
                emitter.particleBirthRate = 0
                
                // Remove tracking
                activeTrails.removeValue(forKey: touch)
                lastTouchPositions.removeValue(forKey: touch)
                touchVelocities.removeValue(forKey: touch)
                
                // Clean up node after all particles die
                let lifetime = TimeInterval(emitter.particleLifetime + emitter.particleLifetimeRange / 2)
                let fadeAction = SKAction.sequence([
                    SKAction.wait(forDuration: lifetime),
                    SKAction.removeFromParent()
                ])
                emitter.run(fadeAction)
                
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
        
        // Configure based on settings
        configureEmitter(emitter, with: viewModel)
        
        addChild(emitter)
        activeTrails[touch] = emitter
    }
    
    private func configureEmitter(_ emitter: SKEmitterNode, with viewModel: MagicalSwirlViewModel) {
        // Basic particle settings
        emitter.particleTexture = createParticleTexture()
        emitter.particleBirthRate = 100 * CGFloat(viewModel.trailThickness)
        emitter.particleLifetime = CGFloat(viewModel.fadeSpeed)
        emitter.particlePositionRange = CGVector(dx: 5, dy: 5)
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.8 / CGFloat(viewModel.fadeSpeed)
        emitter.particleScale = 0.2 * CGFloat(viewModel.trailThickness) / 5.0
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.05
        
        // Color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = getColor(mode: viewModel.colorMode)
        
        // Style adjustments
        switch viewModel.styleMode {
        case .mist:
            emitter.particleTexture = createSoftTexture()
            emitter.particleSpeed = 10
            emitter.particlePositionRange = CGVector(dx: 15, dy: 15)
            emitter.particleAlpha = 0.4
        case .neon:
            emitter.particleBlendMode = .add
            emitter.particleScale = 0.15
            emitter.particleBirthRate *= 1.5
            emitter.particleColorBlendFactor = 1.0
        case .dust:
            emitter.particleScale = 0.05
            emitter.particleBirthRate *= 2.0
            emitter.particleSpeed = 5
            emitter.particleAlpha = 0.6
        case .ink:
            emitter.particleTexture = createSoftTexture()
            emitter.particleAlphaSpeed = -0.2
            emitter.particleScaleSpeed = 0.1
            emitter.particleBlendMode = .alpha
            emitter.particleColor = emitter.particleColor.withAlphaComponent(0.6)
        case .shimmer:
            emitter.particleBlendMode = .add
            emitter.particleRotationSpeed = 2.0
            emitter.particleScaleRange = 0.2
        case .random:
            break
        }
        
        // Glow
        if viewModel.glowStrength > 0 {
            emitter.particleBlendMode = .add
            emitter.particleAlpha = min(1.0, emitter.particleAlpha + 0.3 * CGFloat(viewModel.glowStrength))
        }
    }
    
    private func getColor(mode: MagicalSwirlViewModel.ColorMode) -> UIColor {
        switch mode {
        case .single:
            return UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0) // Cyan-ish
        case .random:
            // Calming Palette: Soft Blues, Teals, Purples, Pinks, Ambers
            let palettes: [UIColor] = [
                UIColor(red: 0.68, green: 0.85, blue: 0.90, alpha: 1.0), // Powder Blue
                UIColor(red: 0.40, green: 0.80, blue: 0.85, alpha: 1.0), // Teal
                UIColor(red: 0.85, green: 0.70, blue: 0.95, alpha: 1.0), // Lavender
                UIColor(red: 0.95, green: 0.75, blue: 0.80, alpha: 1.0), // Soft Pink
                UIColor(red: 1.00, green: 0.85, blue: 0.60, alpha: 1.0)  // Warm Amber
            ]
            return palettes.randomElement() ?? .white
        case .gradient:
            // Time based cycling
            let time = Date().timeIntervalSince1970
            return UIColor(hue: CGFloat(time.remainder(dividingBy: 10) / 10), saturation: 0.6, brightness: 0.9, alpha: 1.0)
        }
    }
    
    // MARK: - Texture Generation
    private func createParticleTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw a nice smooth circle with a slight gradient
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let locations: [CGFloat] = [0.2, 1.0]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)!
        
        context.drawRadialGradient(gradient, startCenter: CGPoint(x: 32, y: 32), startRadius: 0, endCenter: CGPoint(x: 32, y: 32), endRadius: 32, options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image)
    }
    
    private func createSoftTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Very soft, diffuse cloud
        let colors = [UIColor.white.withAlphaComponent(0.8).cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)!
        
        context.drawRadialGradient(gradient, startCenter: CGPoint(x: 32, y: 32), startRadius: 0, endCenter: CGPoint(x: 32, y: 32), endRadius: 32, options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image)
    }
}
