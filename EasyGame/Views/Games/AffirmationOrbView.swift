import SwiftUI
import SceneKit

struct AffirmationOrbView: View {
    @StateObject private var viewModel = AffirmationOrbViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 1. Background (keep it dark for contrast)
            Color.black.ignoresSafeArea()
            
            // 2. SceneKit View
            SceneViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            // 3. UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom Control
                VStack(spacing: 20) {
                    if viewModel.state == .reading {
                        Text("Breathe...")
                            .font(.system(size: 16, weight: .light, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .transition(.opacity)
                    }
                    
                    Button(action: {
                        withAnimation {
                            viewModel.handleButtonPress()
                        }
                    }) {
                        Text(viewModel.buttonText)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmBlue)
                            .frame(width: 200)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.calmBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                    .buttonStyle(SoftButtonStyle())
                    .disabled(viewModel.isButtonDisabled)
                    .opacity(viewModel.isButtonDisabled ? 0.6 : 1.0)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// Wrapper to interface SwiftUI with SceneKit Class
struct SceneViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: AffirmationOrbViewModel
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.pointOfView = nil
        
        let scene = AffirmationOrbScene()
        scene.viewModel = viewModel // Link VM to Scene
        view.scene = scene
        view.delegate = scene // Critical for animation loop
        view.isPlaying = true
        
        // Link Scene back to VM
        viewModel.scene = scene
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
