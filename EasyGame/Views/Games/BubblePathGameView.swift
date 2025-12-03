import SwiftUI

// MARK: - Bubble Path Game View
struct BubblePathGameView: View {
    @StateObject private var viewModel = BubblePathViewModel()
    @State private var screenSize: CGSize = .zero
    @State private var scoreScale: CGFloat = 1.0
    @State private var scoreColor: Color = .white.opacity(0.7)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.2, blue: 0.35),
                        Color(red: 0.25, green: 0.3, blue: 0.5),
                        Color(red: 0.35, green: 0.4, blue: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Path segments
                ForEach(viewModel.pathSegments) { segment in
                    PathSegmentView(segment: segment, screenWidth: geometry.size.width)
                }

                // Bubble
                BubbleView(bubble: viewModel.bubble, radius: 25)

                // Score display
                VStack {
                    HStack {
                        Spacer()
                        Text("Distance: \(viewModel.score)")
                            .font(.headline)
                            .foregroundColor(scoreColor)
                            .scaleEffect(scoreScale)
                            .padding()
                    }
                    Spacer()
                }
                .onChange(of: viewModel.score) { newScore in
                    if newScore == 0 {
                        // Reset animation
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            scoreScale = 1.3
                            scoreColor = Color(red: 1.0, green: 0.8, blue: 0.2) // Gold
                        }

                        // Reset back after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                scoreScale = 1.0
                                scoreColor = .white.opacity(0.7)
                            }
                        }
                    }
                }

                // Touch zones
                HStack(spacing: 0) {
                    // Left tap zone
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewModel.driftLeft()
                                }
                                .onEnded { _ in
                                    viewModel.stopDrift()
                                }
                        )

                    // Right tap zone
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewModel.driftRight()
                                }
                                .onEnded { _ in
                                    viewModel.stopDrift()
                                }
                        )
                }
            }
            .onAppear {
                self.screenSize = geometry.size
                viewModel.startGame(screenSize: geometry.size)
            }
            .onDisappear {
                viewModel.stopGame()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Bubble Path")
    }
}

// MARK: - Path Segment View
struct PathSegmentView: View {
    let segment: PathSegment
    let screenWidth: CGFloat

    var body: some View {
        let centerX = segment.centerX * screenWidth
        // let pathLeft = centerX - segment.width / 2

        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.15))
            .frame(width: segment.width, height: 80)
            .position(x: centerX, y: segment.yPosition)
            .overlay(
                // Path borders for clarity
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: segment.width, height: 80)
                    .position(x: centerX, y: segment.yPosition)
            )
    }
}

// MARK: - Bubble View
struct BubbleView: View {
    let bubble: BubbleState
    let radius: CGFloat

    var body: some View {
        let isHit = bubble.glowLevel > 1.2
        let mainColor = isHit ? Color(red: 1.0, green: 0.8, blue: 0.2) : Color.cyan // Warm Gold
        let coreColor = isHit ? Color.white : Color.white

        return ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            mainColor.opacity(0.6 * bubble.glowLevel),
                            mainColor.opacity(0.2 * bubble.glowLevel),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: radius * 1.5
                    )
                )
                .frame(width: radius * 3, height: radius * 3)

            // Main bubble
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            coreColor.opacity(0.8 * bubble.glowLevel),
                            mainColor.opacity(0.6 * bubble.glowLevel),
                            Color.blue.opacity(0.4 * bubble.glowLevel)
                        ]),
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .blur(radius: 1)
                .overlay(
                    // Highlight
                    Circle()
                        .fill(Color.white.opacity(0.3 * bubble.glowLevel))
                        .frame(width: radius * 0.6, height: radius * 0.6)
                        .offset(x: -radius * 0.3, y: -radius * 0.3)
                )
        }
        .position(bubble.position)
        .animation(.easeOut(duration: 0.1), value: bubble.position)
    }
}
