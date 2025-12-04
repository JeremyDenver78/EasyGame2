import SwiftUI

// MARK: - Landing View
struct LandingView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var heartBeat: CGFloat = 1.0
    @State private var navigateToGames = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Infinite gradient background
                InfiniteGradientBackground()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo section
                    VStack(spacing: 24) {
                        // Heart icon with glow
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 90
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .scaleEffect(heartBeat)

                            // White circle background
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.calmBlue.opacity(0.2), radius: 30, x: 0, y: 15)

                            // Heart icon
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.calmBlue, Color.dreamyPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(heartBeat)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        // Title text
                        VStack(spacing: 12) {
                            Text("Mind Swirl")
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundColor(.softText)

                            Text("Anxiety Relief")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(.lightText)
                        }
                        .opacity(textOpacity)
                    }

                    Spacer()

                    // Start button
                    Button(action: {
                        navigateToGames = true
                    }) {
                        Text("Start Games")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.calmBlue.opacity(0.15), radius: 20, x: 0, y: 10)
                            )
                    }
                    .buttonStyle(SoftButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                    .opacity(buttonOpacity)
                }
            }
            .navigationDestination(isPresented: $navigateToGames) {
                GameSelectionView()
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                buttonOpacity = 1.0
            }

            // Gentle heart pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                heartBeat = 1.05
            }
        }
    }
}
