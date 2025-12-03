import SwiftUI
import SpriteKit

// MARK: - Main View
struct ShapesThatSingView: View {
    @StateObject private var viewModel = ShapesThatSingViewModel()
    @State private var scene: SingingShapeScene?
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

            // SpriteKit Scene (Main Canvas) - ONLY touch handler
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    // CRITICAL: Disable when overlays are showing to prevent double-tap
                    .allowsHitTesting(!viewModel.showMenu && !viewModel.showSettings)
            }

            // Instructions (only if no shapes exist)
            if viewModel.shapes.isEmpty {
                VStack {
                    Spacer()
                    Text("Touch to explore")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .allowsHitTesting(false) // Let taps pass through to SpriteKit
            }

            // Menu Overlay (radial shape selector)
            if viewModel.showMenu {
                menuOverlay
            }

            // Top Bar (back button, settings)
            VStack {
                HStack {
                    // Back Button
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

                    // Settings Button
                    Button(action: {
                        withAnimation {
                            viewModel.showSettings.toggle()
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .allowsHitTesting(true) // Buttons always respond

            // Bottom Controls (clear all)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: viewModel.clearAll) {
                        Image(systemName: "trash")
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
            .allowsHitTesting(true) // Button always responds

            // Settings Overlay
            if viewModel.showSettings {
                settingsOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Warm up audio (non-blocking)
            viewModel.prepareAudio()

            // Setup scene on main thread
            setupScene()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Menu Overlay
    private var menuOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        viewModel.showMenu = false
                    }
                }

            ShapeMenu(position: viewModel.menuPosition) { type in
                // CRITICAL: Only add shape once
                withAnimation {
                    viewModel.addShape(type)
                }
            }
        }
    }

    // MARK: - Settings Overlay
    private var settingsOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        viewModel.showSettings = false
                    }
                }

            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(spacing: 24) {
                    // Collision Sounds Toggle
                    Toggle("Collision Sounds", isOn: $viewModel.isCollisionSoundEnabled)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    // Volume Slider
                    VStack(alignment: .leading) {
                        Text("Volume: \(Int(viewModel.volume * 100))%")
                            .foregroundColor(.white)
                        Slider(value: $viewModel.volume, in: 0.0...1.0)
                    }
                    .padding(.horizontal)

                    // Info Text
                    Text("Tap empty space to add shapes.\nTap shapes to remove them.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: 350)

                Button("Close") {
                    withAnimation {
                        viewModel.showSettings = false
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

    // MARK: - Scene Setup
    private func setupScene() {
        let newScene = SingingShapeScene()
        newScene.scaleMode = .resizeFill
        newScene.viewModel = viewModel
        viewModel.scene = newScene
        self.scene = newScene
    }
}

// MARK: - Shape Menu (Radial Selector)
struct ShapeMenu: View {
    let position: CGPoint
    let onSelect: (ShapeType) -> Void

    var body: some View {
        ZStack {
            ForEach(Array(ShapeType.allCases.enumerated()), id: \.element) { index, type in
                menuItem(for: type, index: index, total: ShapeType.allCases.count)
            }
        }
        .position(position)
        .transition(.scale.combined(with: .opacity))
    }

    private func menuItem(for type: ShapeType, index: Int, total: Int) -> some View {
        let angle = Double(index) * (2.0 * .pi / Double(total)) - .pi / 2
        let radius: CGFloat = 90
        let x = cos(angle) * radius
        let y = sin(angle) * radius

        return Button(action: {
            // CRITICAL: Button action should only fire once
            onSelect(type)
        }) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.title2)
                Text(type.name)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 70)
            .background(type.color.opacity(0.9))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: type.color.opacity(0.6), radius: 10, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle()) // Prevent default button behavior
        .offset(x: x, y: y)
    }
}
