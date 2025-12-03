import Foundation
import Combine
import UIKit
import CoreGraphics

// MARK: - High Performance Sand Engine
class SandEngine: ObservableObject {
    // Simulation Settings
    let width: Int
    let height: Int
    private let particleCount: Int

    // Buffers
    // We use raw pointers for maximum performance (avoiding Array bounds checks in the hot loop)
    var pixelBuffer: UnsafeMutableBufferPointer<UInt32>
    var stateBuffer: UnsafeMutableBufferPointer<UInt8> // 0 = empty, 1 = sand
    var velocityBuffer: UnsafeMutableBufferPointer<Float> // Vertical velocity for gravity

    // Rendering
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

    // State
    @Published var lastImage: UIImage?
    private var isDisposed = false

    // Physics Constants
    private let gravity: Float = 0.2
    private let maxVelocity: Float = 8.0
    private let terminalVelocityByte: UInt8 = 8 // Max pixels to skip per frame

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.particleCount = width * height

        // Allocate buffers
        self.pixelBuffer = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: particleCount)
        self.stateBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: particleCount)
        self.velocityBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: particleCount)

        // Initialize with clear/empty
        self.pixelBuffer.initialize(repeating: 0)
        self.stateBuffer.initialize(repeating: 0)
        self.velocityBuffer.initialize(repeating: 0)
    }

    deinit {
        // Clean up memory
        if !isDisposed {
            pixelBuffer.deallocate()
            stateBuffer.deallocate()
            velocityBuffer.deallocate()
        }
    }

    // MARK: - Interaction
    func emit(at point: CGPoint, in screenSize: CGSize) {
        let x = Int((point.x / screenSize.width) * CGFloat(width))
        let y = Int((point.y / screenSize.height) * CGFloat(height))

        let brushSize = 3 // Radius of sand stream

        for dy in -brushSize...brushSize {
            for dx in -brushSize...brushSize {
                // Circular brush
                if dx*dx + dy*dy > brushSize*brushSize { continue }

                let px = x + dx
                let py = y + dy

                if px >= 0 && px < width && py >= 0 && py < height {
                    let index = py * width + px
                    if stateBuffer[index] == 0 {
                        spawnSand(at: index)
                    }
                }
            }
        }
    }

    private func spawnSand(at index: Int) {
        stateBuffer[index] = 1
        velocityBuffer[index] = 1.0 // Initial velocity

        // Generate nice sand color with noise
        // Format is ARGB (Little Endian: BGRA)
        let variation = Int.random(in: -20...20)
        let r = clamp(235 + variation)
        let g = clamp(200 + variation)
        let b = clamp(140 + variation)

        // 0xAARRGGBB in hex, but little endian puts Alpha at the end or beginning depending on architecture
        // For byteOrder32Little: BGRA in memory, so 0xAABBGGRR in the UInt32 word
        let color: UInt32 = (255 << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
        pixelBuffer[index] = color
    }

    private func clamp(_ val: Int) -> Int {
        return max(0, min(255, val))
    }

    // MARK: - Physics Loop
    func update() {
        // Iterate bottom-up, randomizing X direction to avoid bias
        // We use a separate "touched" tracker implicitly by direction of loop or strictly handling moves
        // For simplicity in this demo, strict bottom-up prevents double-moving in one frame

        // var moved = false

        for y in (0..<(height - 1)).reversed() {
            // Randomize X scan order to prevent "leaning" towers
            let scanLeftToRight = Bool.random()
            let xRange = scanLeftToRight ? Array(0..<width) : Array((0..<width).reversed())

            for x in xRange {
                let index = y * width + x

                if stateBuffer[index] > 0 { // Is Sand

                    // 1. Apply Gravity
                    var vel = velocityBuffer[index]
                    vel += gravity
                    if vel > maxVelocity { vel = maxVelocity }
                    velocityBuffer[index] = vel

                    // Determine how many pixels to fall
                    let steps = Int(vel)

                    // Try to move down 'steps' times
                    if steps > 0 {
                        // Attempt move directly down first
                        let destY = y + steps
                        let actualDestY = min(height - 1, destY)

                        // Check if path is clear to actualDestY
                        // Simplification: Just check the landing spot.
                        // For better physics, we raycast, but for sand simple check is okay.

                        let destIndex = actualDestY * width + x

                        if stateBuffer[destIndex] == 0 {
                            // Move Particle
                            moveParticle(from: index, to: destIndex, vel: vel)
                            // moved = true
                        } else {
                            // Hit something. Reset velocity and try to slide.
                            velocityBuffer[index] = 1.0 // Reset energy

                            // Try diagonals (Sliding)
                            let belowIndex = (y + 1) * width + x
                            if stateBuffer[belowIndex] != 0 {
                                // Down is blocked, try Left/Right
                                let leftX = x - 1
                                let rightX = x + 1
                                let belowLeft = (y + 1) * width + leftX
                                let belowRight = (y + 1) * width + rightX

                                let canGoLeft = leftX >= 0 && stateBuffer[belowLeft] == 0
                                let canGoRight = rightX < width && stateBuffer[belowRight] == 0

                                if canGoLeft && canGoRight {
                                    // Pick random
                                    let goLeft = Bool.random()
                                    moveParticle(from: index, to: goLeft ? belowLeft : belowRight, vel: 1.0)
                                } else if canGoLeft {
                                    moveParticle(from: index, to: belowLeft, vel: 1.0)
                                } else if canGoRight {
                                    moveParticle(from: index, to: belowRight, vel: 1.0)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Generate Image from Buffer
        renderImage()
    }

    private func moveParticle(from: Int, to: Int, vel: Float) {
        stateBuffer[to] = stateBuffer[from]
        pixelBuffer[to] = pixelBuffer[from]
        velocityBuffer[to] = vel

        stateBuffer[from] = 0
        pixelBuffer[from] = 0 // Clear pixel (black/transparent)
        velocityBuffer[from] = 0
    }

    private func renderImage() {
        // Create CGImage from the pixel buffer
        // Note: In production code, you might want to double buffer this to avoid tearing,
        // but for this game, direct access is performant and simple.

        let provider = CGDataProvider(data: Data(bytes: pixelBuffer.baseAddress!, count: particleCount * 4) as CFData)

        if let provider = provider,
           let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
           ) {
            DispatchQueue.main.async {
                self.lastImage = UIImage(cgImage: cgImage)
            }
        }
    }
}
