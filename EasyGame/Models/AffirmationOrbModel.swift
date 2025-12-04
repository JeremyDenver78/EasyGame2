import Foundation
import CoreGraphics

struct OrbParticle {
    var position: SIMD3<Float>
    var targetPosition: SIMD3<Float>
    var color: SIMD3<Float> // RGB
}

struct AffirmationData {
    static let list: [String] = [
        "I am allowed to slow down.",
        "My mind and body can soften in this moment.",
        "I am safe to breathe.",
        "I don’t need to figure it out right now.",
        "I can handle this with calm.",
        "My feelings are valid.",
        "Every breath brings me back.",
        "I am worthy of peace.",
        "I choose gentleness over pressure.",
        "I am doing the best I can.",
        "It’s okay to rest.",
        "I let my thoughts drift by.",
        "I deserve moments of quiet.",
        "I allow myself to feel calm.",
        "I trust myself a little more today.",
        "I release what I cannot control.",
        "My nervous system can unwind.",
        "I choose presence over perfection.",
        "I am allowed to take up space.",
        "My calm expands with every breath.",
        "I can create peace inside myself.",
        "I am strong enough to face this.",
        "I welcome comfort and safety.",
        "I am allowed to pause.",
        "I allow this moment to be simple.",
        "I trust my ability to navigate.",
        "I am grounded.",
        "I release tension I don't need.",
        "I give myself permission to be okay.",
        "I deserve calm and joy."
    ]
}
