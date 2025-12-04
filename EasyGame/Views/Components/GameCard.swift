import SwiftUI

// MARK: - Game Card
struct GameCard: View {
    let game: Game
    @State private var navigateToGame = false

    var body: some View {
        Button(action: {
            navigateToGame = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: game.type.iconColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: game.type.iconName)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                }

                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.type.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.softText)

                    Text(game.type.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.lightText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.lightText.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
                    .shadow(
                        color: Color.calmBlue.opacity(0.08),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
        }
        .buttonStyle(SoftCardButtonStyle(isEnabled: true))
        .navigationDestination(isPresented: $navigateToGame) {
            game.type.destinationView
        }
    }
}
