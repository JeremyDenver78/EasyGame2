import Foundation
import SwiftUI

enum GameType: String, CaseIterable, Identifiable {
    case jigsawPuzzle
    case bubblePath
    case sandfall
    case shapesThatSing
    case magicalSwirl
    case harmonicBloom
    case affirmationOrb

    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .jigsawPuzzle: return "Jigsaw Puzzle"
        case .bubblePath:
            return "Bubble Path"
        case .sandfall:
            return "Sandfall"
        case .shapesThatSing:
            return "Shapes That Sing"
        case .magicalSwirl: return "Magical Swirl"
        case .harmonicBloom: return "Harmonic Bloom"
        case .affirmationOrb: return "Affirmation Orb"
        }
    }
    
    var description: String {
        switch self {
        case .jigsawPuzzle: return "Relax by piecing together beautiful landscapes."
        case .bubblePath:
            return "Guide the bubble through the path. Don't touch the walls!"
        case .sandfall:
            return "Relax with falling sand. Draw patterns and watch them pile up."
        case .shapesThatSing:
            return "Create a soothing ambient soundscape with floating shapes."
        case .magicalSwirl: return "Create soothing trails of light with your touch."
        case .harmonicBloom: return "Watch your environment bloom into light as you listen or speak."
        case .affirmationOrb: return "Find clarity in the chaos. Reveal a message of calm."
        }
    }
    
    var iconName: String {
        switch self {
        case .jigsawPuzzle: return "puzzlepiece.extension"
        case .bubblePath:
            return "circle.grid.cross.fill"
        case .sandfall:
            return "hourglass"
        case .shapesThatSing:
            return "music.quarternote.3"
        case .magicalSwirl: return "sparkles"
        case .harmonicBloom: return "waveform.circle"
        case .affirmationOrb: return "sparkles.rectangle.stack"
        }
    }
    
    var iconColors: [Color] {
        switch self {
        case .jigsawPuzzle: return [Color.calmBlue, Color.calmBlueLight]
        case .bubblePath: return [Color(red: 0.55, green: 0.70, blue: 0.95), Color(red: 0.70, green: 0.82, blue: 1.0)]
        case .sandfall: return [Color.dreamyPeach, Color(red: 1.0, green: 0.80, blue: 0.70)]
        case .shapesThatSing: return [Color.dreamyPurple.opacity(0.6), Color.dreamyPurple]
        case .magicalSwirl: return [Color(red: 0.4, green: 0.2, blue: 0.6), Color(red: 0.6, green: 0.4, blue: 0.8)]
        case .harmonicBloom: return [Color(red: 0.2, green: 0.8, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.8)]
        case .affirmationOrb: return [Color(red: 0.2, green: 0.8, blue: 0.9), Color(red: 0.6, green: 0.3, blue: 0.9)]
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .jigsawPuzzle:
            PuzzleSelectionView()
        case .bubblePath:
            BubblePathGameView()
        case .sandfall:
            SandfallGameView()
        case .shapesThatSing:
            ShapesThatSingView()
        case .magicalSwirl:
            MagicalSwirlView()
        case .harmonicBloom:
            HarmonicBloomView()
        case .affirmationOrb:
            AffirmationOrbView()
        }
    }
}

struct Game: Identifiable {
    let id = UUID()
    let type: GameType
}
