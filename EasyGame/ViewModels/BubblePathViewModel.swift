import Foundation
import Combine
import CoreGraphics

// MARK: - Bubble Path Model
struct PathSegment: Identifiable {
    let id = UUID()
    var centerX: CGFloat // X position of center line (0-1, where 0.5 is middle)
    var width: CGFloat // Width of safe path
    var yPosition: CGFloat // Y position on screen
}

struct BubbleState {
    var position: CGPoint
    var velocity: CGPoint
    var glowLevel: Double // 0.0 to 1.0
}

// MARK: - Bubble Path ViewModel
class BubblePathViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var bubble: BubbleState
    @Published var pathSegments: [PathSegment] = []
    @Published var score: Int = 0

    // MARK: - Game State
    private var gameTimer: Timer?
    private var screenSize: CGSize = .zero
    private let pathWidth: CGFloat = 125 // Width of safe path (increased for bigger bubble)
    private let bubbleRadius: CGFloat = 31.25 // Increased by 25%
    private let scrollSpeed: CGFloat = 2.0 // Points per frame
    private let driftSpeed: CGFloat = 4.0 // Horizontal drift speed
    private var isCollisionPaused: Bool = false

    // MARK: - Initialization
    init() {
        // Start bubble in center
        self.bubble = BubbleState(
            position: CGPoint(x: 0, y: 0),
            velocity: CGPoint.zero,
            glowLevel: 1.0
        )
    }

    // MARK: - Game Control
    func startGame(screenSize: CGSize) {
        self.screenSize = screenSize

        // Reset bubble to center
        bubble.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.7)
        bubble.velocity = .zero
        bubble.glowLevel = 1.0

        // Generate initial path segments
        generateInitialPath()

        // Start game loop
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
        // Restore glow to normal (1.0) - Always run this so flash fades during pause
        if bubble.glowLevel < 1.0 {
            bubble.glowLevel = min(1.0, bubble.glowLevel + 0.01)
        } else if bubble.glowLevel > 1.0 {
            bubble.glowLevel = max(1.0, bubble.glowLevel - 0.02) // Very slow, soft decay
        }

        // Pause game logic if collision occurred
        guard !isCollisionPaused else { return }

        // Move bubble based on velocity
        bubble.position.x += bubble.velocity.x

        // Apply gentle drag to horizontal movement
        bubble.velocity.x *= 0.95

        // Keep bubble on screen (soft boundaries)
        let minX = bubbleRadius
        let maxX = screenSize.width - bubbleRadius
        bubble.position.x = max(minX, min(maxX, bubble.position.x))

        // Scroll path downward
        scrollPath()

        // Check collision with path edges
        checkCollision()

        // Increment score (simple distance traveled)
        score += 1
    }

    // MARK: - Path Management
    private func generateInitialPath() {
        pathSegments.removeAll()

        let segmentHeight: CGFloat = 80
        var yPos: CGFloat = -segmentHeight
        var centerX: CGFloat = 0.5

        // Generate enough segments to fill screen + buffer
        let numSegments = Int(screenSize.height / segmentHeight) + 5

        for i in 0..<numSegments {
            pathSegments.append(PathSegment(
                centerX: centerX,
                width: pathWidth,
                yPosition: yPos
            ))

            yPos += segmentHeight

            // Keep path straight for the first 5 segments (bottom of screen), then random walk
            if i > 5 {
                centerX += CGFloat.random(in: -0.1...0.1)
                centerX = max(0.2, min(0.8, centerX)) // Keep path mostly on screen
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

            pathSegments.insert(PathSegment(
                centerX: newCenterX,
                width: pathWidth,
                yPosition: firstSegment.yPosition - segmentHeight
            ), at: 0)
        }
    }

    // MARK: - Collision Detection
    private func checkCollision() {
        // Find segment at bubble's Y position
        guard let currentSegment = pathSegments.first(where: { segment in
            abs(segment.yPosition - bubble.position.y) < 40
        }) else {
            return
        }

        // Calculate path bounds
        let pathCenterX = currentSegment.centerX * screenSize.width
        let pathLeft = pathCenterX - currentSegment.width / 2
        let pathRight = pathCenterX + currentSegment.width / 2

        // Check if bubble is outside path
        let bubbleLeft = bubble.position.x - bubbleRadius
        let bubbleRight = bubble.position.x + bubbleRadius

        if bubbleLeft < pathLeft || bubbleRight > pathRight {
            // Soft Collision Response
            // 1. Visuals: Warm Gold Flash (not too bright)
            bubble.glowLevel = 1.5

            // 2. Penalty: Reset score
            score = 0

            // 3. Physics: Stop violent movement, just pause
            bubble.velocity = .zero
            // Clamp position to edge so it doesn't look like it's inside the wall
            if bubbleLeft < pathLeft {
                bubble.position.x = pathLeft + bubbleRadius
            } else {
                bubble.position.x = pathRight - bubbleRadius
            }

            // 4. Pacing: Pause for a moment to let player regroup
            isCollisionPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isCollisionPaused = false
            }
        }
    }
}
