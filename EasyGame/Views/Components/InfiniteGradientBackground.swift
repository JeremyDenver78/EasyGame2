import SwiftUI

// MARK: - Infinite Gradient Background
struct InfiniteGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Base gradient - creates depth
            LinearGradient(
                colors: [
                    Color.skyTop,
                    Color.skyMiddle,
                    Color.skyBottom,
                    Color.horizonGlow
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Floating soft orbs for depth
            GeometryReader { geo in
                // Large distant orb (top right)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dreamyPurple.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.05)
                    .offset(y: animateGradient ? -10 : 10)

                // Medium orb (left side)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dreamyMint.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.3)
                    .offset(x: animateGradient ? 8 : -8)

                // Small accent orb (bottom)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dreamyPeach.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.6)
                    .offset(y: animateGradient ? 12 : -12)

                // Horizon glow effect
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: geo.size.width * 1.5, height: 300)
                    .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.85)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}
