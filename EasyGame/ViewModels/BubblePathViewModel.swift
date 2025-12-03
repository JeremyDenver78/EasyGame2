import Foundation
import Combine
import CoreGraphics
import SwiftUI

// MARK: - Bubble Path Model
struct PathSegment: Identifiable {
    let id = UUID()
    var centerX: CGFloat
    var width: CGFloat
    var yPosition: CGFloat
}

struct BubbleState {
    var position: CGPoint
    var velocity: CGPoint
    var glowLevel: Double
    var color: Color = .cyan
}

// MARK: - Bubble Path ViewModel
class BubblePathViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var bubble: BubbleState
    @Published var pathSegments: [PathSegment] = []
    @Published var score: Int = 0
    @Published var trailPositions: [CGPoint] = []

    // MARK: - Game State
    private var gameTimer: Timer?
    private var screenSize: CGSize = .zero
    private let minPathWidth: CGFloat = 125
    private let maxPathWidth: CGFloat = 180
    private let bubbleRadius: CGFloat = 31.25
    private let scrollSpeed: CGFloat = 2.0
    private let driftSpeed: CGFloat = 4.0
    private var isCollisionPaused: Bool = false

    private let maxTrailLength = 15

    // MARK: - Initialization
    init() {
        self.bubble = BubbleState(
            position: CGPoint(x: 0, y: 0),
            velocity: CGPoint.zero,
            glowLevel: 1.0
        )
    }

    // MARK: - Game Control
    func startGame(screenSize: CGSize) {
        self.screenSize = screenSize

        bubble.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.7)
        bubble.velocity = .zero
        bubble.glowLevel = 1.0
        score = 0
        trailPositions.removeAll()

        generateInitialPath()
        startGameLoop()
    }

    func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    // MARK: - Input Handling
    func driftLeft() {
        bubble.velocity.x = -driftSpeed
    }

    func driftRight() {
        bubble.velocity.x = driftSpeed
    }

    func stopDrift() {
        bubble.velocity.x = 0
    }

    // MARK: - Game Loop
    private func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }

    private func updateGame() {
        // Restore glow to normal
        if bubble.glowLevel < 1.0 {
            bubble.glowLevel = min(1.0, bubble.glowLevel + 0.01)
        } else if bubble.glowLevel > 1.0 {
            bubble.glowLevel = max(1.0, bubble.glowLevel - 0.02)
        }

        guard !isCollisionPaused else { return }

        // Move bubble based on velocity
        bubble.position.x += bubble.velocity.x

        // Apply gentle drag to horizontal movement
        bubble.velocity.x *= 0.95

        // Keep bubble on screen
        let minX = bubbleRadius
        let maxX = screenSize.width - bubbleRadius
        bubble.position.x = max(minX, min(maxX, bubble.position.x))

        // Update trail: add current position, keep last 15
        trailPositions.append(bubble.position)
        if trailPositions.count > maxTrailLength {
            trailPositions.removeFirst()
        }

        // Update bubble color based on score (hue cycle every 500 points)
        let hueProgress = (Double(score) / 500.0).truncatingRemainder(dividingBy: 1.0)
        bubble.color = Color(hue: hueProgress, saturation: 0.8, brightness: 0.9)

        scrollPath()
        checkCollision()
        score += 1
    }

    // MARK: - Path Management
    private func generateInitialPath() {
        pathSegments.removeAll()

        let segmentHeight: CGFloat = 80
        var yPos: CGFloat = -segmentHeight
        var centerX: CGFloat = 0.5

        let numSegments = Int(screenSize.height / segmentHeight) + 5

        for i in 0..<numSegments {
            // Alternate between narrow and wider paths for visual variety
            let width: CGFloat
            if i % 2 == 0 {
                width = minPathWidth
            } else {
                width = CGFloat.random(in: minPathWidth...maxPathWidth)
            }

            pathSegments.append(PathSegment(
                centerX: centerX,
                width: width,
                yPosition: yPos
            ))

            yPos += segmentHeight

            if i > 5 {
                centerX += CGFloat.random(in: -0.1...0.1)
                centerX = max(0.2, min(0.8, centerX))
            }
        }
    }

    private func scrollPath() {
        // Move all segments down
        for i in 0..<pathSegments.count {
            pathSegments[i].yPosition += scrollSpeed
        }

        // Remove segments that scrolled off bottom
        pathSegments.removeAll { $0.yPosition > screenSize.height + 100 }

        // Add new segments at top
        if let firstSegment = pathSegments.first, firstSegment.yPosition > -50 {
            let segmentHeight: CGFloat = 80
            var newCenterX = firstSegment.centerX + CGFloat.random(in: -0.1...0.1)
            newCenterX = max(0.2, min(0.8, newCenterX))

            // Vary width: alternate between narrow and wider paths
            let width: CGFloat
            if pathSegments.count % 2 == 0 {
                width = minPathWidth
            } else {
                width = CGFloat.random(in: minPathWidth...maxPathWidth)
            }

            pathSegments.insert(PathSegment(
                centerX: newCenterX,
                width: width,
                yPosition: firstSegment.yPosition - segmentHeight
            ), at: 0)
        }
    }

    // MARK: - Collision Detection
    private func checkCollision() {
        guard let currentSegment = pathSegments.first(where: { segment in
            abs(segment.yPosition - bubble.position.y) < 40
        }) else {
            return
        }

        let pathCenterX = currentSegment.centerX * screenSize.width
        let pathLeft = pathCenterX - currentSegment.width / 2
        let pathRight = pathCenterX + currentSegment.width / 2

        let bubbleLeft = bubble.position.x - bubbleRadius
        let bubbleRight = bubble.position.x + bubbleRadius

        if bubbleLeft < pathLeft || bubbleRight > pathRight {
            handleCollision(pathLeft: pathLeft, pathRight: pathRight)
        }
    }

    private func handleCollision(pathLeft: CGFloat, pathRight: CGFloat) {
        // Play soft collision sound
        BubbleGameAudioEngine.shared.playCollisionSound()

        // Visual feedback: gentle warm flash
        bubble.glowLevel = 1.5

        // Reset score
        score = 0

        // Stop movement
        bubble.velocity = .zero

        // Clamp position to edge
        if bubble.position.x - bubbleRadius < pathLeft {
            bubble.position.x = pathLeft + bubbleRadius
        } else {
            bubble.position.x = pathRight - bubbleRadius
        }

        // Brief pause
        isCollisionPaused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isCollisionPaused = false
        }
    }
}
