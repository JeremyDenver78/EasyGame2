import Foundation
import SwiftUI

enum PuzzleDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var gridDimensions: (rows: Int, cols: Int) {
        switch self {
        case .easy: return (3, 3)
        case .medium: return (5, 5)
        case .hard: return (8, 8)
        }
    }
}

enum PuzzleShape: String, CaseIterable, Identifiable {
    case traditional
    case square
    case random
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .traditional: return "Traditional"
        case .square: return "Square"
        case .random: return "Random"
        }
    }
}

#if canImport(UIKit)
struct PuzzlePiece: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let correctGridPosition: (row: Int, col: Int)
    var currentPosition: CGPoint
    var isLocked: Bool = false
    var size: CGSize
    
    // For Equatable
    static func == (lhs: PuzzlePiece, rhs: PuzzlePiece) -> Bool {
        lhs.id == rhs.id && lhs.currentPosition == rhs.currentPosition && lhs.isLocked == rhs.isLocked
    }
}
#endif

