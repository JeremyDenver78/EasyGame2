import SwiftUI

struct GameSelectionView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.98, blue: 1.0)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.games) { game in
                        if game.isComingSoon {
                            ComingSoonGameCard(game: game)
                        } else {
                            NavigationLink(destination: destinationView(for: game)) {
                                ActiveGameCard(game: game)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Select a Game")
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    func destinationView(for game: Game) -> some View {
        switch game.type {
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
        default:
            Text("Coming Soon")
        }
    }
}

struct ActiveGameCard: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: game.type.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue.opacity(0.7))
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(game.type.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(game.type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.title3)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ComingSoonGameCard: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: game.type.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray.opacity(0.5))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(game.type.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(game.type.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
