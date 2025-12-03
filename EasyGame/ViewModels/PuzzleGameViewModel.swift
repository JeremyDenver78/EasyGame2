#if canImport(UIKit)
import SwiftUI
import UIKit
import Combine

class PuzzleGameViewModel: ObservableObject {
    @Published var pieces: [PuzzlePiece] = []
    @Published var isGameOver: Bool = false
    @Published var selectedImageName: String
    @Published var difficulty: PuzzleDifficulty
    @Published var shape: PuzzleShape
    
    // Board dimensions (for UI scaling)
    var boardSize: CGSize = .zero
    var pieceSize: CGSize = .zero
    
    init(imageName: String, difficulty: PuzzleDifficulty, shape: PuzzleShape) {
        self.selectedImageName = imageName
        self.difficulty = difficulty
        self.shape = shape
    }
    
    func startGame(in boardSize: CGSize) {
        self.boardSize = boardSize
        self.isGameOver = false
        
        guard let fullImage = UIImage(named: self.selectedImageName) else {
            print("Error: Could not load image \(self.selectedImageName)")
            return
        }
        
        // Resize image to fit board aspect ratio/size if needed?
        // For simplicity, we'll assume the board is square or fits the image.
        // Let's resize the UIImage to the boardSize to make math easier.
        let resizedImage = resizeImage(image: fullImage, targetSize: boardSize)
        
        let (rows, cols) = difficulty.gridDimensions
        self.pieceSize = CGSize(width: boardSize.width / CGFloat(cols), height: boardSize.height / CGFloat(rows))
        
        var newPieces = ImageSplitter.split(image: resizedImage, into: rows, and: cols, shape: self.shape)
        
        // Randomize positions
        // We'll scatter them around the bottom or random spots
        for i in 0..<newPieces.count {
            newPieces[i].currentPosition = randomPosition(in: boardSize)
        }
        
        self.pieces = newPieces
    }
    
    func updatePiecePosition(id: UUID, location: CGPoint) {
        if let index = pieces.firstIndex(where: { $0.id == id }) {
            if !pieces[index].isLocked {
                pieces[index].currentPosition = location
            }
        }
    }
    
    func onDragEnd(id: UUID) {
        if let index = pieces.firstIndex(where: { $0.id == id }) {
            let piece = pieces[index]
            let (r, c) = piece.correctGridPosition
            
            // Calculate target point
            let targetX = CGFloat(c) * pieceSize.width + pieceSize.width / 2
            let targetY = CGFloat(r) * pieceSize.height + pieceSize.height / 2
            let targetPoint = CGPoint(x: targetX, y: targetY)
            
            // Distance check
            let distance = hypot(piece.currentPosition.x - targetPoint.x, piece.currentPosition.y - targetPoint.y)
            
            // Snap threshold (e.g., 40 points)
            if distance < 40 {
                pieces[index].currentPosition = targetPoint
                pieces[index].isLocked = true
                checkWinCondition()
            }
        }
    }
    
    private func checkWinCondition() {
        if pieces.allSatisfy({ $0.isLocked }) {
            isGameOver = true
        }
    }
    
    private func randomPosition(in size: CGSize) -> CGPoint {
        // Scatter pieces in a wider area or just randomly on screen
        // For now, random within the board + some buffer?
        // Or better, a separate "tray" area.
        // Let's just randomize within the board for now, but maybe offset.
        let x = CGFloat.random(in: 50...(size.width - 50))
        let y = CGFloat.random(in: 50...(size.height - 50))
        return CGPoint(x: x, y: y)
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        // let size = image.size
        
        // let widthRatio  = targetSize.width  / size.width
        // let heightRatio = targetSize.height / size.height
        
        // We scale the image to fill the target size exactly

        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}
#else
import SwiftUI
class PuzzleGameViewModel: ObservableObject {
    init(imageName: String, difficulty: PuzzleDifficulty, shape: PuzzleShape) {}
}
#endif

