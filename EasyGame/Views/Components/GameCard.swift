import SwiftUI

// MARK: - Game Card
struct GameCard: View {
    let game: Game
    @State private var navigateToGame = false

    var body: some View {
        Button(action: {
            if !game.isComingSoon {
                navigateToGame = true
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: !game.isComingSoon ? game.type.iconColors : [Color.gray.opacity(0.2), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: game.type.iconName)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(!game.isComingSoon ? .white : .gray.opacity(0.5))
                }

                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.type.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(!game.isComingSoon ? .softText : .gray.opacity(0.5))

                    if !game.isComingSoon {
                        Text(game.type.description)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.lightText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Coming Soon")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.gray.opacity(0.4))
                            .italic()
                    }
                }

                Spacer()

                // Chevron
                if !game.isComingSoon {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.lightText.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(!game.isComingSoon ? 0.9 : 0.5))
                    .shadow(
                        color: !game.isComingSoon ? Color.calmBlue.opacity(0.08) : Color.clear,
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
        }
        .buttonStyle(SoftCardButtonStyle(isEnabled: !game.isComingSoon))
        .disabled(game.isComingSoon)
        .navigationDestination(isPresented: $navigateToGame) {
            game.type.destinationView
        }
    }
}
