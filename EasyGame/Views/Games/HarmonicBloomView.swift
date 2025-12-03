import SwiftUI
import WebKit

struct HarmonicBloomView: View {
    @StateObject private var viewModel = HarmonicBloomViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Dark background to match the visualizer
            Color.black.ignoresSafeArea()

            if viewModel.contentMissing {
                // Content Missing State
                contentMissingView
            } else if viewModel.hasMicrophoneAccess {
                // The Web Game
                HarmonicWebView(folderName: "www", fileName: "index")
                    .ignoresSafeArea()
            } else if viewModel.permissionDenied {
                // Denied State UI
                permissionDeniedView
            } else {
                // Loading State
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }

            // Custom Floating Back Button
            backButtonOverlay
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.checkPermissions()
        }
    }

    // MARK: - Subviews
    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.9)) // Cyan
                .padding()

            Text("Enable Microphone")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Harmonic Bloom needs to hear the room to generate art. Please enable access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 40)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.white)
                    .cornerRadius(25)
            }
        }
    }

    private var contentMissingView: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.9)) // Cyan
                .padding()

            Text("Content Not Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("The 'www' folder with the visualizer content is missing from the app bundle. Please add the HTML, CSS, and JavaScript files to continue.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 40)
        }
    }

    private var backButtonOverlay: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                }
                .padding(.leading, 16)
                .padding(.top, 8)

                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Fixed WKWebView Wrapper
struct HarmonicWebView: UIViewRepresentable {
    let folderName: String
    let fileName: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow inline media (required for audio/visualizers)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Create the WebView with a transparent background
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 1. Locate the 'www' folder in the Bundle
        guard let folderURL = Bundle.main.url(forResource: folderName, withExtension: nil) else {
            print("❌ Error: Could not find folder '\(folderName)' in Bundle.")
            return
        }

        // 2. Construct the file URL for 'index.html' inside that folder
        let fileURL = folderURL.appendingPathComponent("\(fileName).html")

        // 3. CRITICAL FIX: Use loadFileURL allowing access to the folder
        // This grants the WebView permission to read CSS/JS files inside 'www'
        webView.loadFileURL(fileURL, allowingReadAccessTo: folderURL)
    }
}
