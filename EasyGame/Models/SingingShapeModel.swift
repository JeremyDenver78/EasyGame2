import Foundation
import SwiftUI
import CoreGraphics

// MARK: - Models

enum ShapeType: String, CaseIterable, Identifiable {
    case circle
    case triangle
    case square
    case hexagon
    case star

    var id: String { rawValue }

    var name: String {
        switch self {
        case .circle: return "Circle"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .hexagon: return "Hexagon"
        case .star: return "Star"
        }
    }

    var iconName: String {
        switch self {
        case .circle: return "circle.fill"
        case .triangle: return "triangle.fill"
        case .square: return "square.fill"
        case .hexagon: return "hexagon.fill"
        case .star: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .circle: return Color(red: 0.6, green: 0.8, blue: 1.0) // Soft Blue
        case .triangle: return Color(red: 1.0, green: 0.9, blue: 0.6) // Soft Yellow
        case .square: return Color(red: 0.8, green: 0.6, blue: 1.0) // Soft Purple
        case .hexagon: return Color(red: 0.6, green: 1.0, blue: 0.8) // Soft Teal
        case .star: return Color(red: 1.0, green: 0.7, blue: 0.7) // Soft Pink
        }
    }

    var loopDuration: TimeInterval {
        switch self {
        case .circle: return 8.0
        case .triangle: return 4.0
        case .square: return 12.0
        case .hexagon: return 6.0
        case .star: return 10.0
        }
    }
}

struct SingingShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    var position: CGPoint
    var scale: CGFloat = 0.0
    var rotation: Double = 0.0
    var brightness: Double = 0.5
    var isPlaying: Bool = false

    // Physics
    var driftVelocity: CGPoint
}
