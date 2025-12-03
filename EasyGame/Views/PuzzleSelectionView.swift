import SwiftUI

// MARK: - Puzzle Image Model
struct PuzzleImage: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let colors: [Color] // For placeholder gradient
}

// MARK: - Puzzle Selection View
struct PuzzleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPuzzleIndex = 0
    @State private var selectedDifficultyString = "Easy"
    @State private var selectedShapeString = "Traditional"
    @State private var appearAnimation = false
    @State private var navigateToGame = false
    
    let puzzles: [PuzzleImage] = [
        PuzzleImage(name: "Lake", imageName: "puzzle_lake", colors: [Color(red: 0.6, green: 0.75, blue: 0.85), Color(red: 0.7, green: 0.82, blue: 0.75)]),
        PuzzleImage(name: "Forest", imageName: "puzzle_forest", colors: [Color(red: 0.55, green: 0.75, blue: 0.65), Color(red: 0.70, green: 0.85, blue: 0.75)]),
        PuzzleImage(name: "Beach", imageName: "puzzle_beach", colors: [Color(red: 0.95, green: 0.90, blue: 0.75), Color(red: 0.50, green: 0.70, blue: 0.90)]),
        PuzzleImage(name: "Meadow", imageName: "puzzle_meadow", colors: [Color(red: 0.80, green: 0.90, blue: 0.60), Color(red: 0.95, green: 0.95, blue: 0.80)]),
        PuzzleImage(name: "Zen", imageName: "puzzle_zen", colors: [Color(red: 0.85, green: 0.80, blue: 0.75), Color(red: 0.60, green: 0.60, blue: 0.65)])
    ]
    
    let difficulties = ["Easy", "Medium", "Hard"]
    let shapes = ["Traditional", "Square", "Random"]
    
    // Computed properties to map strings back to Enums for ViewModel
    var selectedDifficulty: PuzzleDifficulty {
        switch selectedDifficultyString {
        case "Easy": return .easy
        case "Medium": return .medium
        case "Hard": return .hard
        default: return .easy
        }
    }
    
    var selectedShape: PuzzleShape {
        switch selectedShapeString {
        case "Traditional": return .traditional
        case "Square": return .square
        case "Random": return .random
        default: return .traditional
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            InfiniteGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Select a Game")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.calmBlue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Title
                Text("Choose Your Puzzle")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.softText)
                    .padding(.top, 24)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 10)
                
                // Puzzle carousel
                puzzleCarousel
                    .padding(.top, 24)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 15)
                
                // Puzzle name
                Text(puzzles[selectedPuzzleIndex].name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.softText)
                    .padding(.top, 16)
                    .animation(.easeOut(duration: 0.2), value: selectedPuzzleIndex)
                
                Spacer()
                
                // Options section
                VStack(spacing: 24) {
                    // Difficulty selector
                    OptionSelector(
                        title: "Difficulty",
                        options: difficulties,
                        selected: $selectedDifficultyString
                    )
                    
                    // Piece shape selector
                    OptionSelector(
                        title: "Piece Shape",
                        options: shapes,
                        selected: $selectedShapeString
                    )
                }
                .padding(.horizontal, 24)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                
                Spacer()
                
                // Start button
                Button(action: {
                    navigateToGame = true
                }) {
                    Text("Start Game")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.calmBlue, Color(red: 0.55, green: 0.72, blue: 0.92)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.calmBlue.opacity(0.35), radius: 15, x: 0, y: 8)
                        )
                }
                .buttonStyle(SoftButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appearAnimation ? 1 : 0)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToGame) {
            PuzzleGameView(viewModel: PuzzleGameViewModel(
                imageName: puzzles[selectedPuzzleIndex].imageName,
                difficulty: selectedDifficulty,
                shape: selectedShape
            ))
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }
    
    // MARK: - Puzzle Carousel
    private var puzzleCarousel: some View {
        HStack(spacing: 0) {
            // Left arrow
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedPuzzleIndex = (selectedPuzzleIndex - 1 + puzzles.count) % puzzles.count
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.calmBlue)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Puzzle image
            ZStack {
                // Soft shadow/glow behind
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: puzzles[selectedPuzzleIndex].colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .shadow(color: puzzles[selectedPuzzleIndex].colors[0].opacity(0.4), radius: 30, x: 0, y: 15)
                
                // Actual image
                Image(puzzles[selectedPuzzleIndex].imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .id(selectedPuzzleIndex)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
            
            Spacer()
            
            // Right arrow
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedPuzzleIndex = (selectedPuzzleIndex + 1) % puzzles.count
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.calmBlue)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Mountain Shape for Placeholder
struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.85, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Option Selector
struct OptionSelector: View {
    let title: String
    let options: [String]
    @Binding var selected: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.lightText)
            
            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = option
                        }
                    }) {
                        Text(option)
                            .font(.system(size: 15, weight: selected == option ? .semibold : .medium, design: .rounded))
                            .foregroundColor(selected == option ? .calmBlue : .lightText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(selected == option ? Color.white : Color.clear)
                                    .shadow(
                                        color: selected == option ? Color.calmBlue.opacity(0.1) : Color.clear,
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.5))
            )
        }
    }
}
