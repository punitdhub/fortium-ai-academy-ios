import SwiftUI
import UIKit

// MARK: - Colors

extension UIColor {
    convenience init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&value)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// A color that adapts to light and dark mode.
    static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

/// Fortium brand palette (slate blue + amber), tuned for readability.
enum Theme {
    static let brand = Color.adaptive(light: "#3F5F7D", dark: "#A8BDD1")
    static let brandDeep = Color(hex: "#1E2B3A")
    static let brandMid = Color(hex: "#4A6C8C")
    static let gold = Color.adaptive(light: "#A87F40", dark: "#D9B779")
    static let goldSoft = Color.adaptive(light: "#FBF3E4", dark: "#2E2718")
    static let success = Color.adaptive(light: "#2E7D52", dark: "#6FD39A")
    static let successSoft = Color.adaptive(light: "#E6F4EC", dark: "#16291F")
    static let danger = Color.adaptive(light: "#B23B3B", dark: "#F08A8A")
    static let dangerSoft = Color.adaptive(light: "#FBEAEA", dark: "#2E1A1A")
    static let warning = Color.adaptive(light: "#B26A1E", dark: "#F2B36B")
    static let background = Color.adaptive(light: "#F4F6F9", dark: "#111317")
    static let surface = Color.adaptive(light: "#FFFFFF", dark: "#1C1F26")
    static let surfaceRaised = Color.adaptive(light: "#EEF1F5", dark: "#262A33")
    static let stroke = Color.adaptive(light: "#E1E5EC", dark: "#2F3440")

    static let heroGradient = LinearGradient(
        colors: [Color(hex: "#1E2B3A"), Color(hex: "#4A6C8C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "#D9B779"), Color(hex: "#A87F40")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

extension Font {
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

// MARK: - Reusable styles

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.brandMid
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 16)
            .background(isEnabled ? tint : Color.gray.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.headline, weight: .semibold))
            .foregroundStyle(Theme.brand)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 16)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A rounded, tappable chip used for quick answers in the Prompt Builder and onboarding.
struct ChipView: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon) }
            Text(title)
        }
        .font(.rounded(.subheadline, weight: .semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(isSelected ? .white : Theme.brand)
        .background(isSelected ? Theme.brandMid : Theme.surfaceRaised, in: Capsule())
        .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Theme.stroke, lineWidth: 1))
    }
}

/// Simple wrapping layout so chips flow onto multiple lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Circular progress ring.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = Theme.gold

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surfaceRaised, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
    }
}

/// Thin horizontal progress bar.
struct ProgressBar: View {
    let progress: Double
    var tint: Color = Theme.gold
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceRaised)
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
                    .animation(.easeOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Helpers

extension String {
    /// Renders **bold** and _italic_ inline markdown used in lesson content.
    var markdown: AttributedString {
        (try? AttributedString(
            markdown: self,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(self)
    }
}

enum Haptics {
    private static var enabled: Bool { UserDefaults.standard.bool(forKey: SettingsKey.haptics) }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
