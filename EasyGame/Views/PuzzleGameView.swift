import SwiftUI

#if canImport(UIKit)
struct PuzzleGameView: View {
    @StateObject var viewModel: PuzzleGameViewModel
    @State private var boardSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea()
            
            VStack {
                // Top Bar
                HStack {
                    Text("Puzzle")
                        .font(.headline)
                    Spacer()
                    Button("Reset") {
                        viewModel.startGame(in: boardSize)
                    }
                }
                .padding()
                
                Spacer()
                
                // Game Board Area
                GeometryReader { geo in
                    ZStack {
                        // Background Ghost Image (Optional, helps guide)
                        Image(viewModel.selectedImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: boardSize.width, height: boardSize.height)
                            .opacity(0.2)
                            .clipped()
                        
                        // Grid Lines (Optional)
                        
                        // Pieces
                        ForEach(viewModel.pieces) { piece in
                            PieceView(piece: piece)
                                .position(piece.currentPosition)
                                .gesture(
                                    DragGesture(coordinateSpace: .named("BoardSpace"))
                                        .onChanged { value in
                                            if !piece.isLocked {
                                                viewModel.updatePiecePosition(id: piece.id, location: value.location)
                                            }
                                        }
                                        .onEnded { _ in
                                            viewModel.onDragEnd(id: piece.id)
                                        }
                                )
                                .zIndex(piece.isLocked ? 0 : 1) // Locked pieces go to back
                        }
                    }
                    .frame(width: boardSize.width, height: boardSize.height)
                    .background(Color.white)
                    .coordinateSpace(name: "BoardSpace")
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .onAppear {
                        // Determine board size based on available space, keeping aspect ratio square-ish for now
                        let side = min(geo.size.width, geo.size.height) - 40
                        self.boardSize = CGSize(width: side, height: side)
                        viewModel.startGame(in: self.boardSize)
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                
                Spacer()
            }
            
            if viewModel.isGameOver {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack {
                    Text("Wonderful!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("You completed the puzzle.")
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Button("Play Again") {
                        viewModel.startGame(in: boardSize)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.blue.opacity(0.8))
                .cornerRadius(20)
                .shadow(radius: 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PieceView: View {
    let piece: PuzzlePiece
    
    var body: some View {
        Image(uiImage: piece.image)
            .resizable()
            .frame(width: piece.size.width, height: piece.size.height)
            .shadow(radius: piece.isLocked ? 0 : 3)
            // If we had a mask for shapes, we would apply it here
            // .mask(Image(piece.shapeMaskName))
    }
}
#else
struct PuzzleGameView: View {
    @StateObject var viewModel: PuzzleGameViewModel
    var body: some View {
        Text("Please run on iOS Simulator")
    }
}
#endif

