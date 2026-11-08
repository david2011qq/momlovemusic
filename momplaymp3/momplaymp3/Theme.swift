import SwiftUI

enum Theme {
    static let palette: [Color] = [
        Color(red: 1.00, green: 0.42, blue: 0.55), // pink
        Color(red: 1.00, green: 0.62, blue: 0.25), // orange
        Color(red: 0.98, green: 0.78, blue: 0.15), // yellow
        Color(red: 0.35, green: 0.80, blue: 0.45), // green
        Color(red: 0.25, green: 0.75, blue: 0.85), // teal
        Color(red: 0.35, green: 0.55, blue: 1.00), // blue
        Color(red: 0.65, green: 0.45, blue: 0.95)  // purple
    ]

    static func color(_ i: Int) -> Color {
        let n = palette.count
        return palette[((i % n) + n) % n]
    }

    static let emojis = ["🎵", "🐶", "🐱", "🦄", "🚗", "🚀", "🌈", "🐻",
                         "🦁", "🐸", "🍭", "⭐️", "🎈", "🐼", "🦖", "🧸"]

    static let background = LinearGradient(
        colors: [Color(red: 1.0, green: 0.96, blue: 0.78),
                 Color(red: 0.84, green: 0.94, blue: 1.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

func kidFont(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
    .system(size: size, weight: weight, design: .rounded)
}

struct BounceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
