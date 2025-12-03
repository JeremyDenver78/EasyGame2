import SwiftUI
import Foundation
import Combine
import CoreGraphics

// MARK: - App Color Theme
extension Color {
    // Primary palette - soft, dreamy colors
    static let dreamyBlue = Color(red: 0.68, green: 0.82, blue: 0.95)
    static let dreamyPurple = Color(red: 0.82, green: 0.78, blue: 0.94)
    static let dreamyPink = Color(red: 0.95, green: 0.82, blue: 0.88)
    static let dreamyMint = Color(red: 0.78, green: 0.92, blue: 0.89)
    static let dreamyPeach = Color(red: 0.98, green: 0.87, blue: 0.82)
    
    // Background gradient colors
    static let skyTop = Color(red: 0.85, green: 0.91, blue: 0.98)
    static let skyMiddle = Color(red: 0.92, green: 0.90, blue: 0.98)
    static let skyBottom = Color(red: 0.98, green: 0.94, blue: 0.96)
    static let horizonGlow = Color(red: 1.0, green: 0.97, blue: 0.95)
    
    // Text colors
    static let softText = Color(red: 0.35, green: 0.40, blue: 0.50)
    static let lightText = Color(red: 0.55, green: 0.58, blue: 0.65)
    
    // Accent
    static let calmBlue = Color(red: 0.45, green: 0.65, blue: 0.85)
    static let calmBlueLight = Color(red: 0.60, green: 0.78, blue: 0.95)
}

// MARK: - Infinite Gradient Background
struct InfiniteGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient - creates depth
            LinearGradient(
                colors: [
                    Color.skyTop,
                    Color.skyMiddle,
                    Color.skyBottom,
                    Color.horizonGlow
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Floating soft orbs for depth
            GeometryReader { geo in
                // Large distant orb (top right)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dreamyPurple.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.05)
                    .offset(y: animateGradient ? -10 : 10)
                
                // Medium orb (left side)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dreamyMint.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.3)
                    .offset(x: animateGradient ? 8 : -8)
                
                // Small accent orb (bottom)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.dreamyPeach.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.6)
                    .offset(y: animateGradient ? 12 : -12)
                
                // Horizon glow effect
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: geo.size.width * 1.5, height: 300)
                    .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.85)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Landing View
struct LandingView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var heartBeat: CGFloat = 1.0
    @State private var navigateToGames = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Infinite gradient background
                InfiniteGradientBackground()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo section
                    VStack(spacing: 24) {
                        // Heart icon with glow
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 90
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .scaleEffect(heartBeat)
                            
                            // White circle background
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.calmBlue.opacity(0.2), radius: 30, x: 0, y: 15)
                            
                            // Heart icon
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.calmBlue, Color.dreamyPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(heartBeat)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        
                        // Title text
                        VStack(spacing: 12) {
                            Text("Anxiety Relief Games")
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundColor(.softText)
                            
                            Text("Find your calm")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundColor(.lightText)
                        }
                        .opacity(textOpacity)
                    }
                    
                    Spacer()
                    
                    // Start button
                    Button(action: {
                        navigateToGames = true
                    }) {
                        Text("Start Games")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.calmBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.calmBlue.opacity(0.15), radius: 20, x: 0, y: 10)
                            )
                    }
                    .buttonStyle(SoftButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                    .opacity(buttonOpacity)
                }
            }
            .navigationDestination(isPresented: $navigateToGames) {
                GameSelectionView()
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                buttonOpacity = 1.0
            }
            
            // Gentle heart pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                heartBeat = 1.05
            }
        }
    }
}

// MARK: - Soft Button Style
struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Game Selection View
struct GameSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HomeViewModel()
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            InfiniteGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.calmBlue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Title
                Text("Select a Game")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.softText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Game list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.games.enumerated()), id: \.element.id) { index, game in
                            GameCard(game: game)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.08),
                                    value: appearAnimation
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                appearAnimation = true
            }
        }
    }
}

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
            destinationView(for: game)
        }
    }
    
    @ViewBuilder
    func destinationView(for game: Game) -> some View {
        switch game.type {
        case .jigsawPuzzle:
            PuzzleSelectionView()
        case .bubblePath:
            BubblePathGameView()
        case .sandfall:
            SandfallGameView()
        case .shapesThatSing:
            ShapesThatSingView()
        case .magicalSwirl:
            MagicalSwirlView()
        default:
            Text("Coming Soon")
        }
    }
}

// MARK: - Soft Card Button Style
struct SoftCardButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Old Home View (Kept for reference, not used)
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.98, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(viewModel.games) { game in
                            NavigationLink(destination: destinationView(for: game)) {
                                GameCardView(game: game)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Anxiety Relief")
        }
    }
    
    @ViewBuilder
    func destinationView(for game: Game) -> some View {
        switch game.type {
        case .jigsawPuzzle:
            PuzzleSelectionView()
        case .magicalSwirl:
            MagicalSwirlView()
        default:
            Text("Coming Soon")
        }
    }
}

struct GameCardView: View {
    let game: Game
    
    var body: some View {
        VStack {
            Image(systemName: game.type.iconName)
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .foregroundColor(.blue.opacity(0.6))
                .padding()
            
            Text(game.type.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(game.type.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 5)
        }
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Bubble Path Model
struct PathSegment: Identifiable {
    let id = UUID()
    var centerX: CGFloat // X position of center line (0-1, where 0.5 is middle)
    var width: CGFloat // Width of safe path
    var yPosition: CGFloat // Y position on screen
}

struct BubbleState {
    var position: CGPoint
    var velocity: CGPoint
    var glowLevel: Double // 0.0 to 1.0
}

// MARK: - Bubble Path ViewModel
class BubblePathViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var bubble: BubbleState
    @Published var pathSegments: [PathSegment] = []
    @Published var score: Int = 0
    
    // MARK: - Game State
    private var gameTimer: Timer?
    private var screenSize: CGSize = .zero
    private let pathWidth: CGFloat = 125 // Width of safe path (increased for bigger bubble)
    private let bubbleRadius: CGFloat = 31.25 // Increased by 25%
    private let scrollSpeed: CGFloat = 2.0 // Points per frame
    private let driftSpeed: CGFloat = 4.0 // Horizontal drift speed
    private var isCollisionPaused: Bool = false
    
    // MARK: - Initialization
    init() {
        // Start bubble in center
        self.bubble = BubbleState(
            position: CGPoint(x: 0, y: 0),
            velocity: CGPoint.zero,
            glowLevel: 1.0
        )
    }
    
    // MARK: - Game Control
    func startGame(screenSize: CGSize) {
        self.screenSize = screenSize
        
        // Reset bubble to center
        bubble.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.7)
        bubble.velocity = .zero
        bubble.glowLevel = 1.0
        
        // Generate initial path segments
        generateInitialPath()
        
        // Start game loop
        startGameLoop()
    }
    
    func stopGame() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    // MARK: - Input Handling
    func driftLeft() {
        bubble.velocity.x = -driftSpeed
    }
    
    func driftRight() {
        bubble.velocity.x = driftSpeed
    }
    
    func stopDrift() {
        bubble.velocity.x = 0
    }
    
    // MARK: - Game Loop
    private func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    private func updateGame() {
        // Restore glow to normal (1.0) - Always run this so flash fades during pause
        if bubble.glowLevel < 1.0 {
            bubble.glowLevel = min(1.0, bubble.glowLevel + 0.01)
        } else if bubble.glowLevel > 1.0 {
            bubble.glowLevel = max(1.0, bubble.glowLevel - 0.02) // Very slow, soft decay
        }
        
        // Pause game logic if collision occurred
        guard !isCollisionPaused else { return }
        
        // Move bubble based on velocity
        bubble.position.x += bubble.velocity.x
        
        // Apply gentle drag to horizontal movement
        bubble.velocity.x *= 0.95
        
        // Keep bubble on screen (soft boundaries)
        let minX = bubbleRadius
        let maxX = screenSize.width - bubbleRadius
        bubble.position.x = max(minX, min(maxX, bubble.position.x))
        
        // Scroll path downward
        scrollPath()
        
        // Check collision with path edges
        checkCollision()
        
        // Increment score (simple distance traveled)
        score += 1
    }
    
    // MARK: - Path Management
    private func generateInitialPath() {
        pathSegments.removeAll()
        
        let segmentHeight: CGFloat = 80
        var yPos: CGFloat = -segmentHeight
        var centerX: CGFloat = 0.5
        
        // Generate enough segments to fill screen + buffer
        let numSegments = Int(screenSize.height / segmentHeight) + 5
        
        for i in 0..<numSegments {
            pathSegments.append(PathSegment(
                centerX: centerX,
                width: pathWidth,
                yPosition: yPos
            ))
            
            yPos += segmentHeight
            
            // Keep path straight for the first 5 segments (bottom of screen), then random walk
            if i > 5 {
                centerX += CGFloat.random(in: -0.1...0.1)
                centerX = max(0.2, min(0.8, centerX)) // Keep path mostly on screen
            }
        }
    }
    
    private func scrollPath() {
        // Move all segments down
        for i in 0..<pathSegments.count {
            pathSegments[i].yPosition += scrollSpeed
        }
        
        // Remove segments that scrolled off bottom
        pathSegments.removeAll { $0.yPosition > screenSize.height + 100 }
        
        // Add new segments at top
        if let firstSegment = pathSegments.first, firstSegment.yPosition > -50 {
            let segmentHeight: CGFloat = 80
            var newCenterX = firstSegment.centerX + CGFloat.random(in: -0.1...0.1)
            newCenterX = max(0.2, min(0.8, newCenterX))
            
            pathSegments.insert(PathSegment(
                centerX: newCenterX,
                width: pathWidth,
                yPosition: firstSegment.yPosition - segmentHeight
            ), at: 0)
        }
    }
    
    // MARK: - Collision Detection
    private func checkCollision() {
        // Find segment at bubble's Y position
        guard let currentSegment = pathSegments.first(where: { segment in
            abs(segment.yPosition - bubble.position.y) < 40
        }) else {
            return
        }
        
        // Calculate path bounds
        let pathCenterX = currentSegment.centerX * screenSize.width
        let pathLeft = pathCenterX - currentSegment.width / 2
        let pathRight = pathCenterX + currentSegment.width / 2
        
        // Check if bubble is outside path
        let bubbleLeft = bubble.position.x - bubbleRadius
        let bubbleRight = bubble.position.x + bubbleRadius
        
        if bubbleLeft < pathLeft || bubbleRight > pathRight {
            // Soft Collision Response
            // 1. Visuals: Warm Gold Flash (not too bright)
            bubble.glowLevel = 1.5
            
            // 2. Penalty: Reset score
            score = 0
            
            // 3. Physics: Stop violent movement, just pause
            bubble.velocity = .zero
            // Clamp position to edge so it doesn't look like it's inside the wall
            if bubbleLeft < pathLeft {
                bubble.position.x = pathLeft + bubbleRadius
            } else {
                bubble.position.x = pathRight - bubbleRadius
            }
            
            // 4. Pacing: Pause for a moment to let player regroup
            isCollisionPaused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isCollisionPaused = false
            }
        }
    }
}

// MARK: - Bubble Path Game View
struct BubblePathGameView: View {
    @StateObject private var viewModel = BubblePathViewModel()
    @State private var screenSize: CGSize = .zero
    @State private var scoreScale: CGFloat = 1.0
    @State private var scoreColor: Color = .white.opacity(0.7)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.2, blue: 0.35),
                        Color(red: 0.25, green: 0.3, blue: 0.5),
                        Color(red: 0.35, green: 0.4, blue: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Path segments
                ForEach(viewModel.pathSegments) { segment in
                    PathSegmentView(segment: segment, screenWidth: geometry.size.width)
                }
                
                // Bubble
                BubbleView(bubble: viewModel.bubble, radius: 25)
                
                // Score display
                VStack {
                    HStack {
                        Spacer()
                        Text("Distance: \(viewModel.score)")
                            .font(.headline)
                            .foregroundColor(scoreColor)
                            .scaleEffect(scoreScale)
                            .padding()
                    }
                    Spacer()
                }
                .onChange(of: viewModel.score) { newScore in
                    if newScore == 0 {
                        // Reset animation
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            scoreScale = 1.3
                            scoreColor = Color(red: 1.0, green: 0.8, blue: 0.2) // Gold
                        }
                        
                        // Reset back after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                scoreScale = 1.0
                                scoreColor = .white.opacity(0.7)
                            }
                        }
                    }
                }
                
                // Touch zones
                HStack(spacing: 0) {
                    // Left tap zone
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewModel.driftLeft()
                                }
                                .onEnded { _ in
                                    viewModel.stopDrift()
                                }
                        )
                    
                    // Right tap zone
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewModel.driftRight()
                                }
                                .onEnded { _ in
                                    viewModel.stopDrift()
                                }
                        )
                }
            }
            .onAppear {
                self.screenSize = geometry.size
                viewModel.startGame(screenSize: geometry.size)
            }
            .onDisappear {
                viewModel.stopGame()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Bubble Path")
    }
}

// MARK: - Path Segment View
struct PathSegmentView: View {
    let segment: PathSegment
    let screenWidth: CGFloat
    
    var body: some View {
        let centerX = segment.centerX * screenWidth
        // let pathLeft = centerX - segment.width / 2
        
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.15))
            .frame(width: segment.width, height: 80)
            .position(x: centerX, y: segment.yPosition)
            .overlay(
                // Path borders for clarity
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: segment.width, height: 80)
                    .position(x: centerX, y: segment.yPosition)
            )
    }
}

// MARK: - Bubble View
struct BubbleView: View {
    let bubble: BubbleState
    let radius: CGFloat
    
    var body: some View {
        let isHit = bubble.glowLevel > 1.2
        let mainColor = isHit ? Color(red: 1.0, green: 0.8, blue: 0.2) : Color.cyan // Warm Gold
        let coreColor = isHit ? Color.white : Color.white
        
        return ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            mainColor.opacity(0.6 * bubble.glowLevel),
                            mainColor.opacity(0.2 * bubble.glowLevel),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: radius * 1.5
                    )
                )
                .frame(width: radius * 3, height: radius * 3)
            
            // Main bubble
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            coreColor.opacity(0.8 * bubble.glowLevel),
                            mainColor.opacity(0.6 * bubble.glowLevel),
                            Color.blue.opacity(0.4 * bubble.glowLevel)
                        ]),
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .blur(radius: 1)
                .overlay(
                    // Highlight
                    Circle()
                        .fill(Color.white.opacity(0.3 * bubble.glowLevel))
                        .frame(width: radius * 0.6, height: radius * 0.6)
                        .offset(x: -radius * 0.3, y: -radius * 0.3)
                )
        }
        .position(bubble.position)
        .animation(.easeOut(duration: 0.1), value: bubble.position)
    }
}

// MARK: - High Performance Sand Engine
class SandEngine: ObservableObject {
    // Simulation Settings
    let width: Int
    let height: Int
    private let particleCount: Int
    
    // Buffers
    // We use raw pointers for maximum performance (avoiding Array bounds checks in the hot loop)
    var pixelBuffer: UnsafeMutableBufferPointer<UInt32>
    var stateBuffer: UnsafeMutableBufferPointer<UInt8> // 0 = empty, 1 = sand
    var velocityBuffer: UnsafeMutableBufferPointer<Float> // Vertical velocity for gravity
    
    // Rendering
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    
    // State
    @Published var lastImage: UIImage?
    private var isDisposed = false
    
    // Physics Constants
    private let gravity: Float = 0.2
    private let maxVelocity: Float = 8.0
    private let terminalVelocityByte: UInt8 = 8 // Max pixels to skip per frame
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.particleCount = width * height
        
        // Allocate buffers
        self.pixelBuffer = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: particleCount)
        self.stateBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: particleCount)
        self.velocityBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: particleCount)
        
        // Initialize with clear/empty
        self.pixelBuffer.initialize(repeating: 0)
        self.stateBuffer.initialize(repeating: 0)
        self.velocityBuffer.initialize(repeating: 0)
    }
    
    deinit {
        // Clean up memory
        if !isDisposed {
            pixelBuffer.deallocate()
            stateBuffer.deallocate()
            velocityBuffer.deallocate()
        }
    }
    
    // MARK: - Interaction
    func emit(at point: CGPoint, in screenSize: CGSize) {
        let x = Int((point.x / screenSize.width) * CGFloat(width))
        let y = Int((point.y / screenSize.height) * CGFloat(height))
        
        let brushSize = 3 // Radius of sand stream
        
        for dy in -brushSize...brushSize {
            for dx in -brushSize...brushSize {
                // Circular brush
                if dx*dx + dy*dy > brushSize*brushSize { continue }
                
                let px = x + dx
                let py = y + dy
                
                if px >= 0 && px < width && py >= 0 && py < height {
                    let index = py * width + px
                    if stateBuffer[index] == 0 {
                        spawnSand(at: index)
                    }
                }
            }
        }
    }
    
    private func spawnSand(at index: Int) {
        stateBuffer[index] = 1
        velocityBuffer[index] = 1.0 // Initial velocity
        
        // Generate nice sand color with noise
        // Format is ARGB (Little Endian: BGRA)
        let variation = Int.random(in: -20...20)
        let r = clamp(235 + variation)
        let g = clamp(200 + variation)
        let b = clamp(140 + variation)
        
        // 0xAARRGGBB in hex, but little endian puts Alpha at the end or beginning depending on architecture
        // For byteOrder32Little: BGRA in memory, so 0xAABBGGRR in the UInt32 word
        let color: UInt32 = (255 << 24) | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
        pixelBuffer[index] = color
    }
    
    private func clamp(_ val: Int) -> Int {
        return max(0, min(255, val))
    }
    
    // MARK: - Physics Loop
    func update() {
        // Iterate bottom-up, randomizing X direction to avoid bias
        // We use a separate "touched" tracker implicitly by direction of loop or strictly handling moves
        // For simplicity in this demo, strict bottom-up prevents double-moving in one frame
        
        // var moved = false
        
        for y in (0..<(height - 1)).reversed() {
            // Randomize X scan order to prevent "leaning" towers
            let scanLeftToRight = Bool.random()
            let xRange = scanLeftToRight ? Array(0..<width) : Array((0..<width).reversed())
            
            for x in xRange {
                let index = y * width + x
                
                if stateBuffer[index] > 0 { // Is Sand
                    
                    // 1. Apply Gravity
                    var vel = velocityBuffer[index]
                    vel += gravity
                    if vel > maxVelocity { vel = maxVelocity }
                    velocityBuffer[index] = vel
                    
                    // Determine how many pixels to fall
                    let steps = Int(vel)
                    
                    // Try to move down 'steps' times
                    if steps > 0 {
                        // Attempt move directly down first
                        let destY = y + steps
                        let actualDestY = min(height - 1, destY)
                        
                        // Check if path is clear to actualDestY
                        // Simplification: Just check the landing spot.
                        // For better physics, we raycast, but for sand simple check is okay.
                        
                        let destIndex = actualDestY * width + x
                        
                        if stateBuffer[destIndex] == 0 {
                            // Move Particle
                            moveParticle(from: index, to: destIndex, vel: vel)
                            // moved = true
                        } else {
                            // Hit something. Reset velocity and try to slide.
                            velocityBuffer[index] = 1.0 // Reset energy
                            
                            // Try diagonals (Sliding)
                            let belowIndex = (y + 1) * width + x
                            if stateBuffer[belowIndex] != 0 {
                                // Down is blocked, try Left/Right
                                let leftX = x - 1
                                let rightX = x + 1
                                let belowLeft = (y + 1) * width + leftX
                                let belowRight = (y + 1) * width + rightX
                                
                                let canGoLeft = leftX >= 0 && stateBuffer[belowLeft] == 0
                                let canGoRight = rightX < width && stateBuffer[belowRight] == 0
                                
                                if canGoLeft && canGoRight {
                                    // Pick random
                                    let goLeft = Bool.random()
                                    moveParticle(from: index, to: goLeft ? belowLeft : belowRight, vel: 1.0)
                                } else if canGoLeft {
                                    moveParticle(from: index, to: belowLeft, vel: 1.0)
                                } else if canGoRight {
                                    moveParticle(from: index, to: belowRight, vel: 1.0)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Generate Image from Buffer
        renderImage()
    }
    
    private func moveParticle(from: Int, to: Int, vel: Float) {
        stateBuffer[to] = stateBuffer[from]
        pixelBuffer[to] = pixelBuffer[from]
        velocityBuffer[to] = vel
        
        stateBuffer[from] = 0
        pixelBuffer[from] = 0 // Clear pixel (black/transparent)
        velocityBuffer[from] = 0
    }
    
    private func renderImage() {
        // Create CGImage from the pixel buffer
        // Note: In production code, you might want to double buffer this to avoid tearing,
        // but for this game, direct access is performant and simple.
        
        let provider = CGDataProvider(data: Data(bytes: pixelBuffer.baseAddress!, count: particleCount * 4) as CFData)
        
        if let provider = provider,
           let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
           ) {
            DispatchQueue.main.async {
                self.lastImage = UIImage(cgImage: cgImage)
            }
        }
    }
}

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
import SwiftUI
import AVFoundation
import Combine

// MARK: - Models

enum ShapeType: String, CaseIterable, Identifiable {
    case circle
    case triangle
    case square
    case hexagon
    case star
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .circle: return "Circle"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .hexagon: return "Hexagon"
        case .star: return "Star"
        }
    }
    
    var iconName: String {
        switch self {
        case .circle: return "circle.fill"
        case .triangle: return "triangle.fill"
        case .square: return "square.fill"
        case .hexagon: return "hexagon.fill"
        case .star: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .circle: return Color(red: 0.6, green: 0.8, blue: 1.0) // Soft Blue
        case .triangle: return Color(red: 1.0, green: 0.9, blue: 0.6) // Soft Yellow
        case .square: return Color(red: 0.8, green: 0.6, blue: 1.0) // Soft Purple
        case .hexagon: return Color(red: 0.6, green: 1.0, blue: 0.8) // Soft Teal
        case .star: return Color(red: 1.0, green: 0.7, blue: 0.7) // Soft Pink
        }
    }
    
    var loopDuration: TimeInterval {
        switch self {
        case .circle: return 8.0
        case .triangle: return 4.0
        case .square: return 12.0
        case .hexagon: return 6.0
        case .star: return 10.0
        }
    }
}

struct SingingShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    var position: CGPoint
    var scale: CGFloat = 0.0
    var rotation: Double = 0.0
    var brightness: Double = 0.5
    var isPlaying: Bool = false
    
    // Physics
    var driftVelocity: CGPoint
}

// MARK: - Audio Engine

class ShapeAudioEngine {
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let reverb = AVAudioUnitReverb()
    
    // We will use simple buffers for now since synthesizing DSP in Swift without C++ can be tricky/heavy.
    // However, we can create "impulse" buffers or use AVAudioUnitSampler if we had assets.
    // For a pure code solution, we'll use AVAudioSourceNode to generate waveforms.
    
    private var activeNodes: [UUID: AVAudioPlayerNode] = [:]
    private var activeBuffers: [UUID: AVAudioPCMBuffer] = [:]
    
    init() {
        mainMixer = engine.mainMixerNode
        
        // Setup Reverb for that "Ambient" feel
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 50
        
        engine.attach(reverb)
        engine.connect(reverb, to: mainMixer, format: nil)
        
        do {
            try engine.start()
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }
    
    func playSound(for shape: SingingShape) {
        // In a real app, we would load a nice sample.
        // Here, we will generate a simple buffer on the fly or use a basic oscillator.
        // For simplicity and stability in this demo, let's simulate the "idea" with a placeholder
        // or a very simple sine wave buffer.
        
        let frequency: Double
        switch shape.type {
        case .circle: frequency = 440.0 // A4
        case .triangle: frequency = 523.25 // C5
        case .square: frequency = 329.63 // E4
        case .hexagon: frequency = 392.00 // G4
        case .star: frequency = 587.33 // D5
        }
        
        let buffer = generateBuffer(frequency: frequency, duration: 2.0, type: shape.type)
        
        let player = AVAudioPlayerNode()
        engine.attach(player)
        // Connect to reverb
        engine.connect(player, to: reverb, format: buffer.format)
        
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()
        
        // Fade in
        player.volume = 0
        // Animate volume? (AVAudioPlayerNode doesn't animate volume automatically, need a timer or ramp)
        player.volume = 0.5
        
        activeNodes[shape.id] = player
    }
    
    func stopSound(for id: UUID) {
        if let player = activeNodes[id] {
            player.stop()
            engine.detach(player)
            activeNodes.removeValue(forKey: id)
        }
    }
    
    func stopAll() {
        for (id, _) in activeNodes {
            stopSound(for: id)
        }
    }
    
    // Simple Waveform Generator
    private func generateBuffer(frequency: Double, duration: Double, type: ShapeType) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let channels = buffer.floatChannelData!
        let data = channels[0]
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample: Double = 0
            
            // Envelope (Attack/Decay)
            let attack = 0.1
            let decay = duration - attack
            let envelope: Double
            if t < attack {
                envelope = t / attack
            } else {
                envelope = 1.0 - ((t - attack) / decay)
            }
            
            switch type {
            case .circle: // Sine (Bell-ish)
                sample = sin(2.0 * .pi * frequency * t)
            case .triangle: // Triangle wave (Chime-ish)
                let p = 2.0 * frequency * t
                sample = 2.0 * abs(2.0 * (p - floor(p + 0.5))) - 1.0
            case .square: // Square-ish (Pad) - actually let's use a low-passed saw or just sine with harmonics
                sample = sin(2.0 * .pi * frequency * t) + 0.5 * sin(2.0 * .pi * frequency * 2.0 * t)
            case .hexagon: // Pluck (dampened sine)
                sample = sin(2.0 * .pi * frequency * t) * exp(-3.0 * t)
            case .star: // FM-ish
                sample = sin(2.0 * .pi * frequency * t + sin(2.0 * .pi * 5.0 * t))
            }
            
            data[i] = Float(sample * envelope * 0.5) // 0.5 master volume
        }
        
        return buffer
    }
}

// MARK: - ViewModel

class ShapesThatSingViewModel: ObservableObject {
    @Published var shapes: [SingingShape] = []
    @Published var showMenu: Bool = false
    @Published var menuPosition: CGPoint = .zero
    
    private let audio = ShapeAudioEngine()
    private var timer: Timer?
    private var screenSize: CGSize = .zero
    
    func start(screenSize: CGSize) {
        self.screenSize = screenSize
        
        // Start Loop
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        audio.stopAll()
    }
    
    func handleTap(at location: CGPoint) {
        // Check if tapped existing shape
        if let index = shapes.firstIndex(where: { distance($0.position, location) < 50 }) {
            // Remove shape
            let shape = shapes[index]
            audio.stopSound(for: shape.id)
            shapes.remove(at: index)
        } else {
            // Open menu
            menuPosition = location
            showMenu = true
        }
    }
    
    func addShape(_ type: ShapeType) {
        let shape = SingingShape(
            type: type,
            position: menuPosition,
            driftVelocity: CGPoint(
                x: CGFloat.random(in: -0.5...0.5),
                y: CGFloat.random(in: -0.5...0.5)
            )
        )
        shapes.append(shape)
        
        // Start Sound
        audio.playSound(for: shape)
        
        // Animate in
        withAnimation(.spring()) {
            if let index = shapes.firstIndex(where: { $0.id == shape.id }) {
                shapes[index].scale = 1.0
            }
        }
        
        showMenu = false
    }
    
    func clearAll() {
        audio.stopAll()
        withAnimation {
            shapes.removeAll()
        }
    }
    
    private func update() {
        for i in 0..<shapes.count {
            // Drift
            shapes[i].position.x += shapes[i].driftVelocity.x
            shapes[i].position.y += shapes[i].driftVelocity.y
            
            // Rotate
            shapes[i].rotation += 0.2
            
            // Pulse Brightness (Visualizing the loop)
            let time = Date().timeIntervalSince1970
            let loopDuration = shapes[i].type.loopDuration
            let progress = (time.truncatingRemainder(dividingBy: loopDuration)) / loopDuration
            
            // Pulse on the "beat" (start of loop)
            if progress < 0.1 {
                shapes[i].brightness = 1.0 - (progress * 5.0) // Flash
            } else {
                shapes[i].brightness = 0.5 + sin(time) * 0.1 // Gentle breathe
            }
            
            // Bounce off walls
            if shapes[i].position.x < 0 || shapes[i].position.x > screenSize.width {
                shapes[i].driftVelocity.x *= -1
            }
            if shapes[i].position.y < 0 || shapes[i].position.y > screenSize.height {
                shapes[i].driftVelocity.y *= -1
            }
        }
    }
    
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return hypot(a.x - b.x, a.y - b.y)
    }
}

// MARK: - View

struct ShapesThatSingView: View {
    @StateObject private var viewModel = ShapesThatSingViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                
                shapesLayer
                
                if viewModel.showMenu {
                    menuOverlay
                }
                
                controlsLayer
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                viewModel.handleTap(at: location)
            }
            .onAppear {
                viewModel.start(screenSize: geometry.size)
            }
            .onDisappear {
                viewModel.stop()
            }
        }
        .navigationTitle("Shapes That Sing")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Subviews to reduce complexity
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.15, blue: 0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var shapesLayer: some View {
        ForEach(viewModel.shapes) { shape in
            SingingShapeView(shape: shape)
                .position(shape.position)
        }
    }
    
    private var menuOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showMenu = false
                }
            
            ShapeMenu(position: viewModel.menuPosition) { type in
                viewModel.addShape(type)
            }
        }
    }
    
    private var controlsLayer: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: viewModel.clearAll) {
                    Image(systemName: "trash")
                        .foregroundColor(.white.opacity(0.6))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding()
            }
            Spacer()
        }
    }
}

struct SingingShapeView: View {
    let shape: SingingShape
    
    var body: some View {
        ZStack {
            // Glow
            shape.type.shapeView
                .fill(shape.type.color)
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .opacity(shape.brightness * 0.8)
            
            // Core
            shape.type.shapeView
                .fill(shape.type.color.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay(
                    shape.type.shapeView
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
        }
        .rotationEffect(.degrees(shape.rotation))
        .scaleEffect(shape.scale)
        .animation(.spring(), value: shape.scale)
        .animation(.linear(duration: 0.1), value: shape.brightness)
    }
}

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
        .transition(.scale)
    }
    
    private func menuItem(for type: ShapeType, index: Int, total: Int) -> some View {
        let angle = Double(index) * (2.0 * .pi / Double(total)) - .pi / 2
        let radius: CGFloat = 80
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        
        return Button(action: { onSelect(type) }) {
            VStack {
                Image(systemName: type.iconName)
                    .font(.title)
                Text(type.name)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(type.color.opacity(0.8))
            .clipShape(Circle())
            .shadow(radius: 5)
        }
        .offset(x: x, y: y)
    }
}

// Helper for Shape Geometry
extension ShapeType {
    var shapeView: AnyShape {
        switch self {
        case .circle: return AnyShape(Circle())
        case .triangle: return AnyShape(Triangle())
        case .square: return AnyShape(Rectangle())
        case .hexagon: return AnyShape(Hexagon())
        case .star: return AnyShape(Star())
        }
    }
}

// Type-erased Shape
struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// Custom Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let x = rect.minX
        let y = rect.minY
        
        path.move(to: CGPoint(x: x + width * 0.25, y: y))
        path.addLine(to: CGPoint(x: x + width * 0.75, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.5))
        path.addLine(to: CGPoint(x: x + width * 0.75, y: y + height))
        path.addLine(to: CGPoint(x: x + width * 0.25, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.5))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        // Simple 5-point star
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        let points = 5
        let angleStep = .pi * 2 / Double(points)
        
        for i in 0..<points * 2 {
            let angle = Double(i) * angleStep / 2 - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
import SwiftUI
import Combine
import AVFoundation
import CoreHaptics

// MARK: - Audio Engine
class SwirlAudioEngine {
    private let engine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private let reverb = AVAudioUnitReverb()
    
    // Nodes for different sounds
    private let touchPlayer = AVAudioPlayerNode()
    private let movePlayer = AVAudioPlayerNode()
    private let fadePlayer = AVAudioPlayerNode()
    
    init() {
        mainMixer = engine.mainMixerNode
        
        // Setup Reverb
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 40
        
        engine.attach(reverb)
        engine.connect(reverb, to: mainMixer, format: nil)
        
        // Setup Players
        setupPlayer(touchPlayer)
        setupPlayer(movePlayer)
        setupPlayer(fadePlayer)
        
        do {
            try engine.start()
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }
    
    private func setupPlayer(_ player: AVAudioPlayerNode) {
        engine.attach(player)
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(player, to: reverb, format: format)
    }
    
    func playTouchSound(volume: Double) {
        let buffer = generateSineWave(frequency: 440.0, duration: 0.3)
        touchPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        touchPlayer.volume = Float(volume)
        touchPlayer.play()
    }
    
    func playMoveSound(speed: Double, volume: Double) {
        // Continuous whoosh based on speed
        // For simplicity, we'll just play a short noise burst if not already playing or loop it
        // Generating noise on the fly is a bit heavy, let's skip continuous synthesis for now
        // and just play a low tone that pitches up with speed
        
        if !movePlayer.isPlaying {
            let buffer = generateNoise(duration: 1.0)
            movePlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            movePlayer.play()
        }
        
        movePlayer.volume = Float(min(1.0, speed / 1000.0) * volume * 0.5)
        // Pitch shift could be done with AVAudioUnitTimePitch if attached
    }
    
    func stopMoveSound() {
        movePlayer.stop()
    }
    
    func playFadeSound(volume: Double) {
        let buffer = generateSineWave(frequency: 880.0, duration: 0.5)
        fadePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        fadePlayer.volume = Float(volume * 0.3)
        fadePlayer.play()
    }
    
    // Generators
    private func generateSineWave(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let channels = buffer.floatChannelData!
        let data = channels[0]
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (t / duration) // Simple decay
            data[i] = Float(sin(2.0 * .pi * frequency * t) * envelope)
        }
        
        return buffer
    }
    
    private func generateNoise(duration: Double) -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        let channels = buffer.floatChannelData!
        let data = channels[0]
        
        for i in 0..<Int(frameCount) {
            data[i] = Float.random(in: -0.5...0.5)
        }
        
        return buffer
    }
}

class MagicalSwirlViewModel: ObservableObject {
    // MARK: - Settings
    @Published var fadeSpeed: Double = 5.0 // Range: 0.5 - 15.0 seconds
    @Published var trailThickness: Double = 5.0 // Range: 1.0 - 10.0
    @Published var glowStrength: Double = 0.5 // Range: 0.0 - 1.0
    @Published var colorMode: ColorMode = .random
    @Published var styleMode: StyleMode = .random
    @Published var isHapticsEnabled: Bool = true
    @Published var volume: Double = 0.5 // Range: 0.0 - 1.0
    
    // MARK: - Enums
    enum ColorMode: String, CaseIterable, Identifiable {
        case random = "Random"
        case single = "Single"
        case gradient = "Gradient"
        var id: String { self.rawValue }
    }
    
    enum StyleMode: String, CaseIterable, Identifiable {
        case random = "Random"
        case mist = "Mist"
        case neon = "Neon"
        case dust = "Dust"
        case ink = "Ink"
        case shimmer = "Shimmer"
        var id: String { self.rawValue }
    }
    
    // MARK: - Audio & Haptics
    private lazy var audio: SwirlAudioEngine? = {
        return SwirlAudioEngine()
    }()
    private var hapticEngine: CHHapticEngine?
    
    init() {
        // Don't initialize audio/haptics in init - do it lazily
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic Error: \(error)")
        }
    }
    
    func playTouchSound() {
        guard volume > 0 else { return }
        audio?.playTouchSound(volume: volume)
    }
    
    func playMoveSound(speed: Double) {
        guard volume > 0 else { return }
        audio?.playMoveSound(speed: speed, volume: volume)
    }
    
    func stopMoveSound() {
        audio?.stopMoveSound()
    }
    
    func playFadeSound() {
        guard volume > 0 else { return }
        audio?.playFadeSound(volume: volume)
    }
    
    // MARK: - Haptics
    func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func triggerContinuousHaptic(intensity: Double) {
        guard isHapticsEnabled else { return }
        if hapticEngine == nil {
            setupHaptics()
        }
        guard let engine = hapticEngine else { return }
        
        // Create a continuous haptic event
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityParam, sharpnessParam], relativeTime: 0, duration: 0.1)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
}
