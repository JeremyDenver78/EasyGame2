import SpriteKit
import SwiftUI

class SingingShapeScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    weak var viewModel: ShapesThatSingViewModel?

    // Track shape nodes by their ID
    private var shapeNodes: [UUID: SKShapeNode] = [:]

    // Physics Categories
    private struct PhysicsCategory {
        static let shape: UInt32 = 0x1 << 0
        static let edge: UInt32 = 0x1 << 1
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        self.scaleMode = .resizeFill
        view.allowsTransparency = true

        // Setup Physics World
        physicsWorld.gravity = CGVector(dx: 0, dy: 0) // No gravity (floating)
        physicsWorld.contactDelegate = self

        // Create edge loop boundary (shapes bounce off edges)
        let boundary = SKPhysicsBody(edgeLoopFrom: self.frame)
        boundary.categoryBitMask = PhysicsCategory.edge
        boundary.friction = 0.0
        boundary.restitution = 0.8 // Bouncy
        self.physicsBody = boundary

        print("✓ SingingShapeScene initialized with physics")
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if touched an existing shape
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            if let _ = node as? SKShapeNode, let shapeID = node.name, let uuid = UUID(uuidString: shapeID) {
                // Found a shape - remove it
                removeShape(id: uuid)
                return
            }
        }

        // Touched empty space - notify ViewModel to show menu
        viewModel?.handleTapOnEmptySpace(at: location)
    }

    // MARK: - Shape Management
    func addShape(id: UUID, type: ShapeType, position: CGPoint) {
        // Create shape node
        let shapeNode = createShapeNode(type: type)
        shapeNode.position = position
        shapeNode.name = id.uuidString

        // Setup physics body
        let physicsBody = SKPhysicsBody(circleOfRadius: type.size / 2)
        physicsBody.categoryBitMask = PhysicsCategory.shape
        physicsBody.contactTestBitMask = PhysicsCategory.shape | PhysicsCategory.edge
        physicsBody.collisionBitMask = PhysicsCategory.shape | PhysicsCategory.edge
        physicsBody.mass = type.mass
        physicsBody.friction = 0.0
        physicsBody.restitution = 0.6 // Bouncy collisions
        physicsBody.linearDamping = 0.1 // Slight drift slowdown
        physicsBody.angularDamping = 0.2

        // Apply initial random velocity (drift)
        let velocity = CGVector(
            dx: CGFloat.random(in: -50...50),
            dy: CGFloat.random(in: -50...50)
        )
        physicsBody.velocity = velocity

        shapeNode.physicsBody = physicsBody

        // Add glow effect
        addGlowEffect(to: shapeNode, color: type.uiColor)

        // Animate in
        shapeNode.alpha = 0
        shapeNode.setScale(0.1)
        addChild(shapeNode)

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        shapeNode.run(SKAction.group([fadeIn, scaleUp]))

        // Track
        shapeNodes[id] = shapeNode

        // Slow rotation for visual interest
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 20.0)
        shapeNode.run(SKAction.repeatForever(rotate))

        print("✓ Added shape: \(type.rawValue) at \(position)")
    }

    func removeShape(id: UUID) {
        guard let node = shapeNodes[id] else { return }

        // Animate out
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([SKAction.group([fadeOut, scaleDown]), remove])

        node.run(sequence)

        // Remove from tracking
        shapeNodes.removeValue(forKey: id)

        // Notify ViewModel to stop audio
        viewModel?.handleShapeRemoved(id: id)

        print("✓ Removed shape: \(id)")
    }

    func removeAllShapes() {
        for (id, _) in shapeNodes {
            removeShape(id: id)
        }
    }

    // MARK: - Physics Contact Delegate
    func didBegin(_ contact: SKPhysicsContact) {
        // Collision detected
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        // Check if both are shapes (not edges)
        let bothAreShapes = (bodyA.categoryBitMask == PhysicsCategory.shape) &&
                           (bodyB.categoryBitMask == PhysicsCategory.shape)

        if bothAreShapes {
            // Shape-to-shape collision
            viewModel?.handleCollision()
        } else {
            // Shape-to-edge collision (also trigger sound)
            viewModel?.handleCollision()
        }
    }

    // MARK: - Shape Creation
    private func createShapeNode(type: ShapeType) -> SKShapeNode {
        let size = type.size

        let path: CGPath
        switch type {
        case .circle:
            path = CGPath(ellipseIn: CGRect(x: -size/2, y: -size/2, width: size, height: size), transform: nil)

        case .triangle:
            let trianglePath = CGMutablePath()
            trianglePath.move(to: CGPoint(x: 0, y: size/2))
            trianglePath.addLine(to: CGPoint(x: -size/2, y: -size/2))
            trianglePath.addLine(to: CGPoint(x: size/2, y: -size/2))
            trianglePath.closeSubpath()
            path = trianglePath

        case .square:
            path = CGPath(rect: CGRect(x: -size/2, y: -size/2, width: size, height: size), transform: nil)

        case .hexagon:
            let hexPath = CGMutablePath()
            let angles: [CGFloat] = (0..<6).map { CGFloat($0) * .pi / 3.0 }
            for (i, angle) in angles.enumerated() {
                let x = cos(angle) * size/2
                let y = sin(angle) * size/2
                if i == 0 {
                    hexPath.move(to: CGPoint(x: x, y: y))
                } else {
                    hexPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            hexPath.closeSubpath()
            path = hexPath

        case .star:
            let starPath = CGMutablePath()
            let points = 5
            let outerRadius = size / 2
            let innerRadius = outerRadius * 0.4
            for i in 0..<points * 2 {
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                if i == 0 {
                    starPath.move(to: CGPoint(x: x, y: y))
                } else {
                    starPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            starPath.closeSubpath()
            path = starPath
        }

        let node = SKShapeNode(path: path)
        node.fillColor = type.uiColor
        node.strokeColor = UIColor.white.withAlphaComponent(0.5)
        node.lineWidth = 2.0

        return node
    }

    private func addGlowEffect(to node: SKShapeNode, color: UIColor) {
        // Create glow node
        let glowNode = node.copy() as! SKShapeNode
        glowNode.fillColor = color
        glowNode.strokeColor = .clear
        glowNode.alpha = 0.6
        glowNode.zPosition = -1

        // Add blur effect (simulated with scale + alpha)
        glowNode.setScale(1.5)

        node.addChild(glowNode)

        // Pulsing glow animation
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.5),
            SKAction.fadeAlpha(to: 0.8, duration: 1.5)
        ])
        glowNode.run(SKAction.repeatForever(pulse))
    }
}
