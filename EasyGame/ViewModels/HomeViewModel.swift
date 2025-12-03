import Foundation

class HomeViewModel: ObservableObject {
    @Published var games: [Game] = [
        Game(type: .jigsawPuzzle, isComingSoon: false),
        Game(type: .bubblePath, isComingSoon: false),
        Game(type: .sandfall, isComingSoon: false),
        Game(type: .shapesThatSing, isComingSoon: false),
        Game(type: .magicalSwirl, isComingSoon: false),
        Game(type: .game4, isComingSoon: true),
        Game(type: .game5, isComingSoon: true)
    ]
}
