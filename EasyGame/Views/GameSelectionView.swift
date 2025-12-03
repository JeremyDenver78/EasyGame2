import SwiftUI

// MARK: - Game Selection View
struct GameSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HomeViewModel()
    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            // Background
            InfiniteGradientBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.calmBlue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Title
                Text("Select a Game")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.softText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Game list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.games.enumerated()), id: \.element.id) { index, game in
                            GameCard(game: game)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.08),
                                    value: appearAnimation
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                appearAnimation = true
            }
        }
    }
}
