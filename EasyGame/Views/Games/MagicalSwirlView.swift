import SwiftUI
import SpriteKit

struct MagicalSwirlView: View {
    @StateObject private var viewModel = MagicalSwirlViewModel()
    @State private var showSettings = false
    @State private var showInstructions = true
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

            // Instructions Overlay
            if showInstructions {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("Magical Swirl")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Touch and drag your fingers across the screen to create beautiful, flowing trails of light")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 40)

                        Text("Use multiple fingers for more trails!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        Button(action: {
                            withAnimation {
                                showInstructions = false
                            }
                        }) {
                            Text("Start Creating")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                        .padding(.top, 8)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 30)
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Top Bar with Back Button and Title
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                    }

                    Spacer()

                    Text("Magical Swirl")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    // Invisible placeholder for symmetry
                    Color.clear
                        .frame(width: 70)
                }
                .padding(.horizontal)
                .padding(.top, 8)

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
            // Setup scene on main thread, but don't block
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
