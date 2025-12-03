import SwiftUI

// MARK: - View

struct ShapesThatSingView: View {
    @StateObject private var viewModel = ShapesThatSingViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView

                shapesLayer

                if viewModel.showMenu {
                    menuOverlay
                }

                controlsLayer
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                viewModel.handleTap(at: location)
            }
            .onAppear {
                viewModel.start(screenSize: geometry.size)
            }
            .onDisappear {
                viewModel.stop()
            }
        }
        .navigationTitle("Shapes That Sing")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Subviews to reduce complexity
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.15, blue: 0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var shapesLayer: some View {
        ForEach(viewModel.shapes) { shape in
            SingingShapeView(shape: shape)
                .position(shape.position)
        }
    }

    private var menuOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showMenu = false
                }

            ShapeMenu(position: viewModel.menuPosition) { type in
                viewModel.addShape(type)
            }
        }
    }

    private var controlsLayer: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: viewModel.clearAll) {
                    Image(systemName: "trash")
                        .foregroundColor(.white.opacity(0.6))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding()
            }
            Spacer()
        }
    }
}

struct SingingShapeView: View {
    let shape: SingingShape

    var body: some View {
        ZStack {
            // Glow
            shape.type.shapeView
                .fill(shape.type.color)
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .opacity(shape.brightness * 0.8)

            // Core
            shape.type.shapeView
                .fill(shape.type.color.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay(
                    shape.type.shapeView
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
        }
        .rotationEffect(.degrees(shape.rotation))
        .scaleEffect(shape.scale)
        .animation(.spring(), value: shape.scale)
        .animation(.linear(duration: 0.1), value: shape.brightness)
    }
}

struct ShapeMenu: View {
    let position: CGPoint
    let onSelect: (ShapeType) -> Void

    var body: some View {
        ZStack {
            ForEach(Array(ShapeType.allCases.enumerated()), id: \.element) { index, type in
                menuItem(for: type, index: index, total: ShapeType.allCases.count)
            }
        }
        .position(position)
        .transition(.scale)
    }

    private func menuItem(for type: ShapeType, index: Int, total: Int) -> some View {
        let angle = Double(index) * (2.0 * .pi / Double(total)) - .pi / 2
        let radius: CGFloat = 80
        let x = cos(angle) * radius
        let y = sin(angle) * radius

        return Button(action: { onSelect(type) }) {
            VStack {
                Image(systemName: type.iconName)
                    .font(.title)
                Text(type.name)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(type.color.opacity(0.8))
            .clipShape(Circle())
            .shadow(radius: 5)
        }
        .offset(x: x, y: y)
    }
}

// MARK: - Helper for Shape Geometry

extension ShapeType {
    var shapeView: AnyShape {
        switch self {
        case .circle: return AnyShape(Circle())
        case .triangle: return AnyShape(Triangle())
        case .square: return AnyShape(Rectangle())
        case .hexagon: return AnyShape(Hexagon())
        case .star: return AnyShape(Star())
        }
    }
}

// MARK: - Type-erased Shape

struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let x = rect.minX
        let y = rect.minY

        path.move(to: CGPoint(x: x + width * 0.25, y: y))
        path.addLine(to: CGPoint(x: x + width * 0.75, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.5))
        path.addLine(to: CGPoint(x: x + width * 0.75, y: y + height))
        path.addLine(to: CGPoint(x: x + width * 0.25, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.5))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        // Simple 5-point star
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        let points = 5
        let angleStep = .pi * 2 / Double(points)

        for i in 0..<points * 2 {
            let angle = Double(i) * angleStep / 2 - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
