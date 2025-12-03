import SwiftUI
import SpriteKit

struct MagicalSwirlView: View {
    @StateObject private var viewModel = MagicalSwirlViewModel()
    @State private var showSettings = false
    
    // Create scene once
    @State private var scene: MagicalSwirlScene = {
        let scene = MagicalSwirlScene()
        scene.scaleMode = .resizeFill
        return scene
    }()
    
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
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .onAppear {
                    scene.viewModel = viewModel
                }
                .onChange(of: viewModel.fadeSpeed) { _ in updateScene() }
                .onChange(of: viewModel.trailThickness) { _ in updateScene() }
                .onChange(of: viewModel.glowStrength) { _ in updateScene() }
                .onChange(of: viewModel.colorMode) { _ in updateScene() }
                .onChange(of: viewModel.styleMode) { _ in updateScene() }
            
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
                                Text("Fade Speed: \(Int(viewModel.fadeSpeed))s")
                                    .foregroundColor(.white)
                                Slider(value: $viewModel.fadeSpeed, in: 0.5...15.0)
                            }
                            
                            // Trail Thickness
                            VStack(alignment: .leading) {
                                Text("Trail Thickness: \(Int(viewModel.trailThickness))")
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
                                Text("Volume")
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
        .navigationBarHidden(true)
    }
    
    private func updateScene() {
        // Trigger any necessary updates in the scene
        // Since the scene holds a reference to the viewModel, it can read the new values directly
        // when creating new trails.
        // If we wanted to update existing trails, we'd need a method in the scene.
        scene.viewModel = viewModel
    }
}

