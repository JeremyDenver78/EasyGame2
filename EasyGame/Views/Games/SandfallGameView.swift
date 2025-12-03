import SwiftUI

// MARK: - Game View
struct SandfallGameView: View {
    // Increase resolution for realism (e.g. 1/2 screen width)
    @StateObject private var engine = SandEngine(width: 200, height: 350)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = engine.lastImage {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none) // Keep edges sharp (pixel art style)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                // Instructions
                VStack {
                    Text("Touch and drag to pour sand")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 50)
                    Spacer()
                }
            }
            // Continuous Touch Handling
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Convert touch view coordinates to simulation coordinates
                        engine.emit(at: value.location, in: geometry.size)
                    }
            )
        }
        // The Game Loop
        .onAppear {
            // Nothing to start, the TimelineView handles the tick
        }
        .overlay(
            TimelineView(.animation) { _ in
                // This block runs every frame (60/120Hz)
                Color.clear
                    .onChange(of: Date()) { _ in
                        engine.update()
                    }
                    .onAppear {
                        // Prime the loop for older iOS versions if needed
                        engine.update()
                    }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Sandfall")
    }
}
