import UIKit

enum EdgeType {
    case flat
    case outTab
    case inTab
}

class ShapeUtils {
    
    // Generates a path for the given shape type.
    // rect: The bounding box of the *logical* piece (the grid cell).
    static func path(for shape: PuzzleShape, size: CGSize, edges: (top: EdgeType, bottom: EdgeType, left: EdgeType, right: EdgeType)) -> UIBezierPath {
        switch shape {
        case .square:
            return UIBezierPath(rect: CGRect(origin: .zero, size: size))
        case .traditional:
            return jigsawPath(size: size, edges: edges)
        case .random:
            return randomPath(size: size)
        }
    }
    
    private static func jigsawPath(size: CGSize, edges: (top: EdgeType, bottom: EdgeType, left: EdgeType, right: EdgeType)) -> UIBezierPath {
        let path = UIBezierPath()
        let w = size.width
        let h = size.height
        let tabSize = min(w, h) * 0.25 // Tab size relative to piece
        
        // Top Edge
        path.move(to: CGPoint(x: 0, y: 0))
        addTab(to: path, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w, y: 0), type: edges.top, tabSize: tabSize, vertical: false)
        
        // Right Edge
        addTab(to: path, start: CGPoint(x: w, y: 0), end: CGPoint(x: w, y: h), type: edges.right, tabSize: tabSize, vertical: true)
        
        // Bottom Edge
        addTab(to: path, start: CGPoint(x: w, y: h), end: CGPoint(x: 0, y: h), type: edges.bottom, tabSize: tabSize, vertical: false)
        
        // Left Edge
        addTab(to: path, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), type: edges.left, tabSize: tabSize, vertical: true)
        
        path.close()
        return path
    }
    
    private static func addTab(to path: UIBezierPath, start: CGPoint, end: CGPoint, type: EdgeType, tabSize: CGFloat, vertical: Bool) {
        if type == .flat {
            path.addLine(to: end)
            return
        }
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        let p1 = CGPoint(x: start.x + dx * 0.35, y: start.y + dy * 0.35)
        let p2 = CGPoint(x: start.x + dx * 0.65, y: start.y + dy * 0.65)
        
        path.addLine(to: p1)
        
        // Normal vector calculation
        var normal = CGPoint(x: dy, y: -dx)
        let len = sqrt(normal.x*normal.x + normal.y*normal.y)
        normal = CGPoint(x: normal.x / len, y: normal.y / len)
        
        let direction: CGFloat = (type == .outTab) ? -1.0 : 1.0
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
    
    private static func randomPath(size: CGSize) -> UIBezierPath {
        let w = size.width
        let h = size.height
        let type = Int.random(in: 0...6)
        let path = UIBezierPath()
        
        switch type {
        case 0: // Circle/Oval
            path.addArc(withCenter: CGPoint(x: w/2, y: h/2), radius: min(w, h)/2, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        case 1: // Triangle
            path.move(to: CGPoint(x: w/2, y: 0))
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.close()
        case 2: // Diamond
            path.move(to: CGPoint(x: w/2, y: 0))
            path.addLine(to: CGPoint(x: w, y: h/2))
            path.addLine(to: CGPoint(x: w/2, y: h))
            path.addLine(to: CGPoint(x: 0, y: h/2))
            path.close()
        case 3: // Star-ish
             let center = CGPoint(x: w/2, y: h/2)
             let points = 5
             let outerRadius = min(w, h)/2
             let innerRadius = outerRadius * 0.4
             let angleIncrement = CGFloat.pi * 2 / CGFloat(points * 2)
             
             for i in 0..<(points * 2) {
                 let radius = (i % 2 == 0) ? outerRadius : innerRadius
                 let angle = CGFloat(i) * angleIncrement - CGFloat.pi / 2
                 let point = CGPoint(
                     x: center.x + cos(angle) * radius,
                     y: center.y + sin(angle) * radius
                 )
                 if i == 0 {
                     path.move(to: point)
                 } else {
                     path.addLine(to: point)
                 }
             }
             path.close()
        case 4: // Square
            return UIBezierPath(rect: CGRect(origin: .zero, size: size))
        case 5: // Traditional-ish (Random Jigsaw)
            let edges: (EdgeType, EdgeType, EdgeType, EdgeType) = (
                Bool.random() ? .outTab : .inTab,
                Bool.random() ? .outTab : .inTab,
                Bool.random() ? .outTab : .inTab,
                Bool.random() ? .outTab : .inTab
            )
            return jigsawPath(size: size, edges: edges)
        default: // Blob (Random curves)
            path.move(to: CGPoint(x: 0, y: h/2))
            path.addCurve(to: CGPoint(x: w, y: h/2), controlPoint1: CGPoint(x: w/3, y: 0), controlPoint2: CGPoint(x: 2*w/3, y: h))
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.close()
        }
        
        return path
    }
}
