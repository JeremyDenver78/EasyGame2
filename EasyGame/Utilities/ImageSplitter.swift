#if canImport(UIKit)
import UIKit

enum EdgeStyle {
    case classic
    case semicircle
    case triangle
    case wave
    case jagged
}

class ImageSplitter {
    static func split(image: UIImage, into rows: Int, and cols: Int, shape: PuzzleShape) -> [PuzzlePiece] {
        var pieces: [PuzzlePiece] = []
        
        let imgWidth = image.size.width
        let imgHeight = image.size.height
        
        let pieceWidth = imgWidth / CGFloat(cols)
        let pieceHeight = imgHeight / CGFloat(rows)
        
        // Buffer for tabs/shapes sticking out
        let buffer = max(pieceWidth, pieceHeight) * 0.5 // Increased buffer for wilder shapes
        
        // Pre-calculate edges
        // We need both direction (in/out) and style (classic/circle/etc)
        
        struct EdgeDef {
            var isOut: Bool
            var style: EdgeStyle
        }
        
        var verticalEdges = Array(repeating: Array(repeating: EdgeDef(isOut: false, style: .classic), count: cols), count: rows)
        var horizontalEdges = Array(repeating: Array(repeating: EdgeDef(isOut: false, style: .classic), count: cols), count: rows)
        
        // Initialize edges
        for r in 0..<rows {
            for c in 0..<cols-1 {
                let isOut = Bool.random()
                let style: EdgeStyle
                if shape == .random {
                    style = [.classic, .semicircle, .triangle, .wave, .jagged].randomElement()!
                } else {
                    style = .classic
                }
                verticalEdges[r][c] = EdgeDef(isOut: isOut, style: style)
            }
        }
        for r in 0..<rows-1 {
            for c in 0..<cols {
                let isOut = Bool.random()
                let style: EdgeStyle
                if shape == .random {
                    style = [.classic, .semicircle, .triangle, .wave, .jagged].randomElement()!
                } else {
                    style = .classic
                }
                horizontalEdges[r][c] = EdgeDef(isOut: isOut, style: style)
            }
        }
        
        for r in 0..<rows {
            for c in 0..<cols {
                let x = CGFloat(c) * pieceWidth
                let y = CGFloat(r) * pieceHeight
                
                // Determine edges
                var edges: (EdgeType, EdgeType, EdgeType, EdgeType) = (.flat, .flat, .flat, .flat)
                var styles: (EdgeStyle, EdgeStyle, EdgeStyle, EdgeStyle) = (.classic, .classic, .classic, .classic)
                
                // Top
                if r == 0 { edges.0 = .flat }
                else {
                    let def = horizontalEdges[r-1][c]
                    edges.0 = def.isOut ? .inTab : .outTab // If neighbor is Out (Down), we are In (Up)
                    // Wait, my definition of "isOut" for horizontal was "tab points Down".
                    // If neighbor at r-1 has "Out" (Down), then it sticks into us. So we have an "In" tab.
                    // Correct.
                    styles.0 = def.style
                }
                
                // Bottom
                if r == rows - 1 { edges.1 = .flat }
                else {
                    let def = horizontalEdges[r][c]
                    edges.1 = def.isOut ? .outTab : .inTab
                    styles.1 = def.style
                }
                
                // Left
                if c == 0 { edges.2 = .flat }
                else {
                    let def = verticalEdges[r][c-1]
                    edges.2 = def.isOut ? .inTab : .outTab // If neighbor is Out (Right), we are In (Left)
                    styles.2 = def.style
                }
                
                // Right
                if c == cols - 1 { edges.3 = .flat }
                else {
                    let def = verticalEdges[r][c]
                    edges.3 = def.isOut ? .outTab : .inTab
                    styles.3 = def.style
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
                    
                    let path = ShapeUtils.path(for: shape, size: CGSize(width: pieceWidth, height: pieceHeight), edges: edges, styles: styles)
                    
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
