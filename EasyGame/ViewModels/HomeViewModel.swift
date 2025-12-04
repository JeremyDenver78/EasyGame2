import Foundation

class HomeViewModel: ObservableObject {
    @Published var games: [Game] = [
        Game(type: .jigsawPuzzle),
        Game(type: .bubblePath),
        Game(type: .sandfall),
        Game(type: .shapesThatSing),
        Game(type: .magicalSwirl),
        Game(type: .harmonicBloom),
        Game(type: .affirmationOrb)
    ]
}
