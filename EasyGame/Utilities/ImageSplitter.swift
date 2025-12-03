#if canImport(UIKit)
import UIKit

class ImageSplitter {
    static func split(image: UIImage, into rows: Int, and cols: Int, shape: PuzzleShape) -> [PuzzlePiece] {
        var pieces: [PuzzlePiece] = []
        
        let imgWidth = image.size.width
        let imgHeight = image.size.height
        
        let pieceWidth = imgWidth / CGFloat(cols)
        let pieceHeight = imgHeight / CGFloat(rows)
        
        // Buffer for tabs/shapes sticking out
        let buffer = max(pieceWidth, pieceHeight) * 0.5 // Increased buffer for wilder shapes
        
        // Pre-calculate edge directions (in/out tabs)
        var verticalEdges = Array(repeating: Array(repeating: false, count: cols), count: rows)
        var horizontalEdges = Array(repeating: Array(repeating: false, count: cols), count: rows)

        // Initialize edges
        for r in 0..<rows {
            for c in 0..<cols-1 {
                verticalEdges[r][c] = Bool.random()
            }
        }
        for r in 0..<rows-1 {
            for c in 0..<cols {
                horizontalEdges[r][c] = Bool.random()
            }
        }
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * pieceWidth
                let y = CGFloat(r) * pieceHeight
                
                // Determine edges
                var edges: (EdgeType, EdgeType, EdgeType, EdgeType) = (.flat, .flat, .flat, .flat)

                // Top
                if r == 0 { edges.0 = .flat }
                else {
                    let isOut = horizontalEdges[r-1][c]
                    edges.0 = isOut ? .inTab : .outTab // If neighbor is Out (Down), we are In (Up)
                }

                // Bottom
                if r == rows - 1 { edges.1 = .flat }
                else {
                    let isOut = horizontalEdges[r][c]
                    edges.1 = isOut ? .outTab : .inTab
                }

                // Left
                if c == 0 { edges.2 = .flat }
                else {
                    let isOut = verticalEdges[r][c-1]
                    edges.2 = isOut ? .inTab : .outTab // If neighbor is Out (Right), we are In (Left)
                }

                // Right
                if c == cols - 1 { edges.3 = .flat }
                else {
                    let isOut = verticalEdges[r][c]
                    edges.3 = isOut ? .outTab : .inTab
                }
                
                // Crop Rect (with buffer)
                let cropX = x - buffer
                let cropY = y - buffer
                let cropW = pieceWidth + buffer * 2
                let cropH = pieceHeight + buffer * 2
                let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
                
                // Create a new image context to draw the masked piece
                let renderer = UIGraphicsImageRenderer(size: cropRect.size)
                let pieceImage = renderer.image { context in
                    let cgContext = context.cgContext
                    cgContext.translateBy(x: buffer, y: buffer)

                    let path = ShapeUtils.path(for: shape, size: CGSize(width: pieceWidth, height: pieceHeight), edges: edges)

                    path.addClip()
                    image.draw(at: CGPoint(x: -x, y: -y))
                    
                    // Optional: Stroke
                    // UIColor.black.withAlphaComponent(0.3).setStroke()
                    // path.lineWidth = 1
                    // path.stroke()
                }
                
                let piece = PuzzlePiece(
                    image: pieceImage,
                    correctGridPosition: (r, c),
                    currentPosition: .zero,
                    size: cropRect.size
                )
                pieces.append(piece)
            }
        }
        
        return pieces
    }
}
#endif
