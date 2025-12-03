import SwiftUI
import SpriteKit

struct HarmonicBloomView: View {
    @StateObject private var viewModel = HarmonicBloomViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var scene: HarmonicBloomScene?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Game Layer
            if viewModel.hasMicrophoneAccess {
                if let scene = scene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                }
            } else if viewModel.permissionDenied {
                // Denied State
                VStack(spacing: 20) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text("Microphone Access Required")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Harmonic Bloom needs to hear the room to generate art.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
            } else {
                // Loading State
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }

            // Controls Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, 20)

                Spacer()

                if viewModel.hasMicrophoneAccess {
                    Text("Speak or make sounds to visualize")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.checkPermissions()
            setupScene()
        }
        .onDisappear {
            viewModel.stopAudio()
        }
    }

    private func setupScene() {
        let newScene = HarmonicBloomScene()
        newScene.scaleMode = .resizeFill
        newScene.viewModel = viewModel
        self.scene = newScene
    }
}
