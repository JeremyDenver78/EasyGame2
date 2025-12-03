import Foundation
import SwiftUI
import SpriteKit

// MARK: - Shape Type
enum ShapeType: String, CaseIterable, Identifiable {
    case circle
    case triangle
    case square
    case hexagon
    case star

    var id: String { rawValue }

    var name: String {
        rawValue.capitalized
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

    // Base frequency for continuous loop sound
    var baseFrequency: Double {
        switch self {
        case .circle: return 261.63   // C4
        case .triangle: return 303.00 // D#4 - matches sound module with ADSR envelope
        case .square: return 261.63   // C4 - softer, more peaceful
        case .hexagon: return 523.25  // C5
        case .star: return 440.00     // A4 - less high-pitched
        }
    }

    var color: Color {
        switch self {
        case .circle: return Color(red: 0.4, green: 0.8, blue: 1.0) // Cyan
        case .triangle: return Color(red: 1.0, green: 0.6, blue: 0.8) // Pink
        case .square: return Color(red: 0.5, green: 1.0, blue: 0.5) // Green
        case .hexagon: return Color(red: 1.0, green: 0.8, blue: 0.4) // Orange
        case .star: return Color(red: 0.8, green: 0.5, blue: 1.0) // Purple
        }
    }

    var uiColor: UIColor {
        switch self {
        case .circle: return UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
        case .triangle: return UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
        case .square: return UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0)
        case .hexagon: return UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        case .star: return UIColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 1.0)
        }
    }

    // Physics properties
    var mass: CGFloat {
        switch self {
        case .circle: return 1.0
        case .triangle: return 0.8
        case .square: return 1.2
        case .hexagon: return 1.0
        case .star: return 0.9
        }
    }

    var size: CGFloat {
        return 60.0 // Base size for all shapes
    }
}

// MARK: - Singing Shape (SpriteKit-based)
struct SingingShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    var position: CGPoint

    init(type: ShapeType, position: CGPoint) {
        self.type = type
        self.position = position
    }
}
