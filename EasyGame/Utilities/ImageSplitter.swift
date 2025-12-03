#if canImport(UIKit)
import UIKit

enum EdgeType {
    case flat
    case outTab
    case inTab
}

enum EdgeStyle {
    case classic
    case semicircle
    case triangle
    case wave
    case jagged
}

class ShapeUtils {
    
    // Generates a path for the given shape type.
    static func path(for shape: PuzzleShape, size: CGSize, 
                     edges: (top: EdgeType, bottom: EdgeType, left: EdgeType, right: EdgeType),
                     styles: (top: EdgeStyle, bottom: EdgeStyle, left: EdgeStyle, right: EdgeStyle)) -> UIBezierPath {
        switch shape {
        case .square:
            return UIBezierPath(rect: CGRect(origin: .zero, size: size))
        case .traditional:
            // Traditional forces classic style
            return jigsawPath(size: size, edges: edges, styles: (.classic, .classic, .classic, .classic))
        case .random:
            return jigsawPath(size: size, edges: edges, styles: styles)
        }
    }
    
    private static func jigsawPath(size: CGSize, 
                                   edges: (top: EdgeType, bottom: EdgeType, left: EdgeType, right: EdgeType),
                                   styles: (top: EdgeStyle, bottom: EdgeStyle, left: EdgeStyle, right: EdgeStyle)) -> UIBezierPath {
        let path = UIBezierPath()
        let w = size.width
        let h = size.height
        let tabSize = min(w, h) * 0.25 // Base tab size
        
        // Top Edge
        path.move(to: CGPoint(x: 0, y: 0))
        addEdge(to: path, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w, y: 0), type: edges.top, style: styles.top, tabSize: tabSize)
        
        // Right Edge
        addEdge(to: path, start: CGPoint(x: w, y: 0), end: CGPoint(x: w, y: h), type: edges.right, style: styles.right, tabSize: tabSize)
        
        // Bottom Edge
        addEdge(to: path, start: CGPoint(x: w, y: h), end: CGPoint(x: 0, y: h), type: edges.bottom, style: styles.bottom, tabSize: tabSize)
        
        // Left Edge
        addEdge(to: path, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), type: edges.left, style: styles.left, tabSize: tabSize)
        
        path.close()
        return path
    }
    
    private static func addEdge(to path: UIBezierPath, start: CGPoint, end: CGPoint, type: EdgeType, style: EdgeStyle, tabSize: CGFloat) {
        if type == .flat {
            path.addLine(to: end)
            return
        }
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        // Normal vector calculation
        var normal = CGPoint(x: dy, y: -dx)
        let len = sqrt(normal.x*normal.x + normal.y*normal.y)
        normal = CGPoint(x: normal.x / len, y: normal.y / len)
        
        let direction: CGFloat = (type == .outTab) ? -1.0 : 1.0
        
        switch style {
        case .classic:
            addClassicTab(to: path, start: start, end: end, normal: normal, direction: direction, tabSize: tabSize)
        case .semicircle:
            addSemicircleTab(to: path, start: start, end: end, normal: normal, direction: direction, tabSize: tabSize)
        case .triangle:
            addTriangleTab(to: path, start: start, end: end, normal: normal, direction: direction, tabSize: tabSize)
        case .wave:
            addWaveEdge(to: path, start: start, end: end, normal: normal, direction: direction, tabSize: tabSize)
        case .jagged:
            addJaggedEdge(to: path, start: start, end: end, normal: normal, direction: direction, tabSize: tabSize)
        }
    }
    
    private static func addClassicTab(to path: UIBezierPath, start: CGPoint, end: CGPoint, normal: CGPoint, direction: CGFloat, tabSize: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        let p1 = CGPoint(x: start.x + dx * 0.35, y: start.y + dy * 0.35)
        let p2 = CGPoint(x: start.x + dx * 0.65, y: start.y + dy * 0.65)
        
        path.addLine(to: p1)
        
        let tabHeight = tabSize * direction
        
        let cp1 = CGPoint(
            x: p1.x + normal.x * tabHeight * 1.2,
            y: p1.y + normal.y * tabHeight * 1.2
        )
        
        let cp2 = CGPoint(
            x: p2.x + normal.x * tabHeight * 1.2,
            y: p2.y + normal.y * tabHeight * 1.2
        )
        
        path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        path.addLine(to: end)
    }
    
    private static func addSemicircleTab(to path: UIBezierPath, start: CGPoint, end: CGPoint, normal: CGPoint, direction: CGFloat, tabSize: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        // Large semicircle
        let p1 = CGPoint(x: start.x + dx * 0.2, y: start.y + dy * 0.2)
        let p2 = CGPoint(x: start.x + dx * 0.8, y: start.y + dy * 0.8)
        
        path.addLine(to: p1)
        
        // Control points for a semi-circle approximation
        // Height of arc
        let h = tabSize * 1.2 * direction
        
        // Midpoint
        // let mid = CGPoint(x: start.x + dx * 0.5, y: start.y + dy * 0.5)
        // let tip = CGPoint(x: mid.x + normal.x * h, y: mid.y + normal.y * h)
        
        // We can use an arc or a curve. Curve is easier to join.
        // For a nice round shape:
        let cp1 = CGPoint(x: p1.x + normal.x * h * 0.8, y: p1.y + normal.y * h * 0.8)
        let cp2 = CGPoint(x: p2.x + normal.x * h * 0.8, y: p2.y + normal.y * h * 0.8)
        
        path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        path.addLine(to: end)
    }
    
    private static func addTriangleTab(to path: UIBezierPath, start: CGPoint, end: CGPoint, normal: CGPoint, direction: CGFloat, tabSize: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        let p1 = CGPoint(x: start.x + dx * 0.3, y: start.y + dy * 0.3)
        let p2 = CGPoint(x: start.x + dx * 0.7, y: start.y + dy * 0.7)
        
        path.addLine(to: p1)
        
        let h = tabSize * 1.2 * direction
        let tip = CGPoint(
            x: start.x + dx * 0.5 + normal.x * h,
            y: start.y + dy * 0.5 + normal.y * h
        )
        
        path.addLine(to: tip)
        path.addLine(to: p2)
        path.addLine(to: end)
    }
    
    private static func addWaveEdge(to path: UIBezierPath, start: CGPoint, end: CGPoint, normal: CGPoint, direction: CGFloat, tabSize: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        // S-curve
        // Two control points
        // One pushes out, one pushes in (relative to the line)
        // But we need to respect "direction" (in/out) for the dominant feature?
        // Or just make it a big wave.
        
        // If direction is OUT, we want the net area to be positive?
        // Let's just do a big sine wave.
        
        let p1 = CGPoint(x: start.x + dx * 0.33, y: start.y + dy * 0.33)
        let p2 = CGPoint(x: start.x + dx * 0.66, y: start.y + dy * 0.66)
        
        let h = tabSize * 0.8 * direction
        
        let cp1 = CGPoint(x: p1.x + normal.x * h, y: p1.y + normal.y * h)
        let cp2 = CGPoint(x: p2.x - normal.x * h, y: p2.y - normal.y * h)
        
        path.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
    }
    
    private static func addJaggedEdge(to path: UIBezierPath, start: CGPoint, end: CGPoint, normal: CGPoint, direction: CGFloat, tabSize: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let steps = 5
        let stepX = dx / CGFloat(steps)
        let stepY = dy / CGFloat(steps)
        
        let h = tabSize * 0.4 * direction
        
        for i in 1...steps {
            let prevX = start.x + stepX * CGFloat(i-1)
            let prevY = start.y + stepY * CGFloat(i-1)
            
            let nextX = start.x + stepX * CGFloat(i)
            let nextY = start.y + stepY * CGFloat(i)
            
            // Zig zag
            if i % 2 != 0 {
                let midX = (prevX + nextX) / 2 + normal.x * h
                let midY = (prevY + nextY) / 2 + normal.y * h
                path.addLine(to: CGPoint(x: midX, y: midY))
            } else {
                let midX = (prevX + nextX) / 2 - normal.x * h
                let midY = (prevY + nextY) / 2 - normal.y * h
                path.addLine(to: CGPoint(x: midX, y: midY))
            }
            path.addLine(to: CGPoint(x: nextX, y: nextY))
        }
    }
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
