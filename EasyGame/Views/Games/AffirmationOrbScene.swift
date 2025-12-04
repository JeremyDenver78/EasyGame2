import SpriteKit
import SceneKit
import UIKit

class AffirmationOrbScene: SCNScene, SCNSceneRendererDelegate {
    
    // Configuration
    private let particleCount = 12000
    private let sphereRadius: Float = 10.0
    
    // Geometry
    private var geometryNode: SCNNode?
    private var geometrySource: SCNGeometrySource?
    private var geometryElement: SCNGeometryElement?
    
    // Data Buffers (Arrays for position data)
    private var currentPositions: [SIMD3<Float>] = []
    private var targetPositions: [SIMD3<Float>] = []
    private var colors: [SIMD3<Float>] = []
    
    // Animation State
    private var isAnimating = false
    private var animationStartTime: TimeInterval = 0
    private var animationDuration: TimeInterval = 2.0
    private var animationCompletion: (() -> Void)?
    
    weak var viewModel: AffirmationOrbViewModel?
    
    override init() {
        super.init()
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupScene() {
        background.contents = UIColor.black
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 30)
        rootNode.addChildNode(cameraNode)
        
        // Initialize Particles
        initializeParticles()
        createGeometry()
        
        // Start rotating the orb
        let rotate = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: 20))
        geometryNode?.runAction(rotate, forKey: "rotate")
    }
    
    // MARK: - Particle Logic
    
    private func initializeParticles() {
        currentPositions = []
        targetPositions = []
        colors = []
        
        // Spherical Distribution (Fibonacci Sphere)
        for i in 0..<particleCount {
            let iFloat = Float(i)
            let countFloat = Float(particleCount)
            
            let phi = acos(-1.0 + (2.0 * iFloat) / countFloat)
            let theta = sqrt(countFloat * Float.pi) * phi
            
            let x = sphereRadius * cos(theta) * sin(phi)
            let y = sphereRadius * sin(theta) * sin(phi)
            let z = sphereRadius * cos(phi)
            
            let pos = SIMD3<Float>(x, y, z)
            
            // Random Jitter for organic look
            let jitter = SIMD3<Float>(
                Float.random(in: -0.2...0.2),
                Float.random(in: -0.2...0.2),
                Float.random(in: -0.2...0.2)
            )
            
            currentPositions.append(pos + jitter)
            targetPositions.append(pos + jitter) // Initially target is self
            
            // Color based on depth (Z)
            let depth = (z / sphereRadius) // -1 to 1
            // Soft purple palette (brighter core, subtle depth variance)
            let base = SIMD3<Float>(0.75, 0.68, 0.95)
            let variance = SIMD3<Float>(0.06 * depth, 0.08 * depth, 0.04 * depth)
            colors.append(base + variance)
        }
    }
    
    private func createGeometry() {
        // Create raw data for vertices
        let vertexData = Data(bytes: currentPositions, count: currentPositions.count * MemoryLayout<SIMD3<Float>>.stride)
        
        let source = SCNGeometrySource(
            data: vertexData,
            semantic: .vertex,
            vectorCount: particleCount,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD3<Float>>.stride
        )
        self.geometrySource = source
        
        // Colors
        var colorData = Data()
        for color in colors {
            // Convert SIMD3 to UIColor bytes (RGBA)
            let r = UInt8(color.x * 255)
            let g = UInt8(color.y * 255)
            let b = UInt8(color.z * 255)
            colorData.append(contentsOf: [r, g, b, 255])
        }
        
        let colorSource = SCNGeometrySource(
            data: colorData,
            semantic: .color,
            vectorCount: particleCount,
            usesFloatComponents: false,
            componentsPerVector: 4,
            bytesPerComponent: 1,
            dataOffset: 0,
            dataStride: 4
        )
        
        // Element (Points)
        var indices = [UInt32](0..<UInt32(particleCount))
        let elementData = Data(bytes: &indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(
            data: elementData,
            primitiveType: .point,
            primitiveCount: particleCount,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )
        self.geometryElement = element
        
        // Geometry
        let geometry = SCNGeometry(sources: [source, colorSource], elements: [element])
        
        // Material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.readsFromDepthBuffer = false
        material.writesToDepthBuffer = false
        geometry.materials = [material]

        
        // Node
        let node = SCNNode(geometry: geometry)
        rootNode.addChildNode(node)
        self.geometryNode = node
    }
    
    // MARK: - Text Generation
    
    private func generateTextPoints(_ text: String) -> [SIMD3<Float>] {
        // 1. Setup Context
        let fontSize: CGFloat = 42
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        let maxWidth: CGFloat = 320
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        
        let width = Int(ceil(maxWidth)) + 20
        let height = Int(ceil(boundingRect.height)) + 40
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: 0
        ) else { return [] }
        
        // 2. Draw Text
        UIGraphicsPushContext(context)
        context.translateBy(x: 10, y: CGFloat(height) - 10) // Padding and flip
        context.scaleBy(x: 1.0, y: -1.0)
        let textRect = CGRect(x: 0, y: 0, width: maxWidth, height: boundingRect.height)
        (text as NSString).draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        UIGraphicsPopContext()
        
        // 3. Scan Pixels
        guard let data = context.data else { return [] }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height)
        
        var points: [SIMD3<Float>] = []
        let scale: Float = 0.04 // Smaller scale to keep text within the orb
        
        for y in 0..<height {
            for x in 0..<width {
                let pixel = buffer[y * width + x]
                if pixel > 128 { // If pixel is visible
                    // Random sampling to reduce density if needed
                    if Float.random(in: 0...1) < 0.55 {
                        let px = (Float(x) - Float(width) / 2) * scale
                        let py = (Float(height - y) - Float(height) / 2) * scale // Flip Y
                        points.append(SIMD3<Float>(px, py, 0))
                    }
                }
            }
        }
        return points
    }
    
    // MARK: - Morphing Logic
    
    func morphToText(_ text: String, completion: @escaping () -> Void) {
        // Stop rotation for readability
        geometryNode?.removeAction(forKey: "rotate")
        
        let runRotation = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.5)
        geometryNode?.runAction(runRotation)
        
        let textPoints = generateTextPoints(text)
        
        // Map points
        for i in 0..<particleCount {
            if i < textPoints.count {
                targetPositions[i] = textPoints[i]
            } else {
                // Excess particles float in a background ring
                let angle = Float.random(in: 0...(Float.pi * 2))
                let radius = Float.random(in: 15...25)
                targetPositions[i] = SIMD3<Float>(
                    cos(angle) * radius,
                    sin(angle) * radius,
                    Float.random(in: -5...5)
                )
            }
        }
        
        startAnimation(duration: 2.0, completion: completion)
    }
    
    func morphToSphere(completion: @escaping () -> Void) {
        // Calculate sphere positions again (or check if we saved them)
        for i in 0..<particleCount {
            let iFloat = Float(i)
            let countFloat = Float(particleCount)
            
            let phi = acos(-1.0 + (2.0 * iFloat) / countFloat)
            let theta = sqrt(countFloat * Float.pi) * phi
            
            let x = sphereRadius * cos(theta) * sin(phi)
            let y = sphereRadius * sin(theta) * sin(phi)
            let z = sphereRadius * cos(phi)
            
            targetPositions[i] = SIMD3<Float>(x, y, z)
        }
        
        startAnimation(duration: 2.0, completion: completion)
        
        // Restart rotation
        let rotate = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: 20))
        geometryNode?.runAction(rotate, forKey: "rotate")
    }
    
    private func startAnimation(duration: TimeInterval, completion: @escaping () -> Void) {
        animationStartTime = Date().timeIntervalSince1970
        animationDuration = duration
        animationCompletion = completion
        isAnimating = true
    }
    
    // MARK: - Render Loop (Frame Update)
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard isAnimating else { return }
        
        let now = Date().timeIntervalSince1970
        let elapsed = now - animationStartTime
        let progress = Float(min(1.0, elapsed / animationDuration))
        
        // Ease InOut
        let t = progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2
        
        // Interpolate
        var updatedPositions = [SIMD3<Float>]()
        updatedPositions.reserveCapacity(particleCount)
        
        // Note: In a real heavy app, use Metal Compute Shaders.
        // For 12k points on modern iOS, linear loop is acceptable (~2ms).
        for i in 0..<particleCount {
            let current = currentPositions[i]
            let target = targetPositions[i]
            
            // Simple Lerp
            // Use eased factor to make the drift responsive but smooth
            let factor = max(0.05, min(0.25, 0.08 + 0.22 * t))
            let newPos = current + (target - current) * factor
            
            // Or exact tween based on time:
            // let start = (we would need to store start pos).
            // Let's stick to "seeking" behavior like the JS version (it uses GSAP).
            // To emulate GSAP properly without storing StartPos for every particle every time:
            // Just move 'current' towards 'target' by a factor.
            
            updatedPositions.append(newPos)
            currentPositions[i] = newPos
        }
        
        // Update Geometry
        updateGeometryData(with: currentPositions)
        
        // Check completion
        if progress >= 0.99 {
            isAnimating = false
            DispatchQueue.main.async {
                self.animationCompletion?()
            }
        }
    }
    
    private func updateGeometryData(with positions: [SIMD3<Float>]) {
        let vertexData = Data(bytes: positions, count: positions.count * MemoryLayout<SIMD3<Float>>.stride)
        
        let source = SCNGeometrySource(
            data: vertexData,
            semantic: .vertex,
            vectorCount: particleCount,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD3<Float>>.stride
        )
        
        // Replace source (needs to be done on main thread usually, or carefully synced)
        // geometryElement stays the same
        if let element = geometryElement, let colorSource = geometryNode?.geometry?.sources(for: .color).first {
             let newGeometry = SCNGeometry(sources: [source, colorSource], elements: [element])
            
            // Carry over materials
            newGeometry.materials = geometryNode?.geometry?.materials ?? []
            geometryNode?.geometry = newGeometry
        }
    }
}
