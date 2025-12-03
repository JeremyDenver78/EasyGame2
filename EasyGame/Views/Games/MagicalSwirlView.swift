import SwiftUI
import SpriteKit

struct MagicalSwirlView: View {
    @StateObject private var viewModel = MagicalSwirlViewModel()
    @State private var showSettings = false
    @State private var scene: MagicalSwirlScene?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15), // Deep Navy
                    Color(red: 0.1, green: 0.05, blue: 0.2),   // Dark Purple
                    Color(red: 0.0, green: 0.1, blue: 0.15)    // Deep Teal
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Main Game Canvas
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
            }

            // Simple Instructions (disappears on first touch)
            if !viewModel.hasCreatedFirstSwirl {
                VStack {
                    Spacer()
                    Text("Touch and drag to create magical swirls")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            }

            // Simple Back Button (top left)
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .regular))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)

                    Spacer()
                }

                Spacer()
            }

            // Settings Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showSettings.toggle()
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.4)))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding()
                }
            }

            // Settings Overlay
            if showSettings {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showSettings = false
                        }
                    }

                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    ScrollView {
                        VStack(spacing: 24) {
                            // Fade Speed
                            VStack(alignment: .leading) {
                                Text("Fade Speed: \(String(format: "%.1f", viewModel.fadeSpeed))s")
                                    .foregroundColor(.white)
                                Slider(value: $viewModel.fadeSpeed, in: 0.5...15.0)
                            }

                            // Trail Thickness
                            VStack(alignment: .leading) {
                                Text("Trail Thickness: \(String(format: "%.1f", viewModel.trailThickness))")
                                    .foregroundColor(.white)
                                Slider(value: $viewModel.trailThickness, in: 1.0...10.0)
                            }

                            // Glow Strength
                            VStack(alignment: .leading) {
                                Text("Glow Strength: \(Int(viewModel.glowStrength * 100))%")
                                    .foregroundColor(.white)
                                Slider(value: $viewModel.glowStrength, in: 0.0...1.0)
                            }

                            // Color Mode
                            VStack(alignment: .leading) {
                                Text("Color Mode")
                                    .foregroundColor(.white)
                                Picker("Color Mode", selection: $viewModel.colorMode) {
                                    ForEach(MagicalSwirlViewModel.ColorMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }

                            // Style Mode
                            VStack(alignment: .leading) {
                                Text("Style Mode")
                                    .foregroundColor(.white)
                                Picker("Style Mode", selection: $viewModel.styleMode) {
                                    ForEach(MagicalSwirlViewModel.StyleMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }

                            // Haptics Toggle
                            Toggle("Haptics", isOn: $viewModel.isHapticsEnabled)
                                .foregroundColor(.white)

                            // Volume
                            VStack(alignment: .leading) {
                                Text("Volume: \(Int(viewModel.volume * 100))%")
                                    .foregroundColor(.white)
                                Slider(value: $viewModel.volume, in: 0.0...1.0)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)

                    Button("Close") {
                        withAnimation {
                            showSettings = false
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.8)))
                .padding(30)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Warm up audio and haptics (non-blocking)
            viewModel.prepareAudio()
            viewModel.prepareHaptics()

            // Setup scene on main thread
            setupScene()
        }
    }

    private func setupScene() {
        // Create and configure scene
        let newScene = MagicalSwirlScene()
        newScene.scaleMode = .resizeFill
        newScene.viewModel = viewModel
        self.scene = newScene
    }
}
