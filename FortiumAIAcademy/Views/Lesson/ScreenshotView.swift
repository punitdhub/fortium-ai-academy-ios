import SwiftUI

/// A real screenshot of Claude with numbered callouts. Tap to view full screen and pinch to zoom.
struct ScreenshotView: View {
    let card: LessonCard
    let tint: Color

    @State var showFullScreen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let platform = card.platform {
                Label(platform, systemImage: platformIcon(platform))
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.12), in: Capsule())
            }

            if let image = card.screenshotImage {
                Button { showFullScreen = true } label: {
                    AnnotatedScreenshot(image: image, highlights: card.highlights ?? [])
                        .frame(maxHeight: 520)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Screenshot: \(card.title). Double-tap to enlarge.")

                legend

                Label("Tap the picture to zoom in", systemImage: "hand.tap")
                    .font(.rounded(.caption))
                    .foregroundStyle(.secondary)
            } else {
                missingPlaceholder
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let image = card.screenshotImage {
                ZoomableScreenshot(image: image, highlights: card.highlights ?? [], title: card.title)
            }
        }
    }

    @ViewBuilder
    private var legend: some View {
        let labeled = (card.highlights ?? []).enumerated().filter { $0.element.label != nil }
        if !labeled.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(labeled, id: \.offset) { index, highlight in
                    HStack(alignment: .top, spacing: 10) {
                        CalloutNumber(number: index + 1)
                        Text((highlight.label ?? "").markdown)
                            .font(.rounded(.body))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .card(padding: 14)
        }
    }

    /// Shown only in debug builds, so you can see which screenshots still need to be captured.
    private var missingPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 40))
                .foregroundStyle(tint)
            Text("Screenshot needed")
                .font(.rounded(.headline, weight: .bold))
            Text(card.image ?? "(no file name)")
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("See SCREENSHOTS.md. This placeholder is hidden in App Store builds.")
                .font(.rounded(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
        )
    }

    private func platformIcon(_ platform: String) -> String {
        let lower = platform.lowercased()
        if lower.contains("iphone") || lower.contains("mobile") || lower.contains("phone") { return "iphone" }
        if lower.contains("desktop") || lower.contains("mac") { return "desktopcomputer" }
        return "globe"
    }
}

/// The image with callout rectangles drawn at fractional positions.
struct AnnotatedScreenshot: View {
    let image: UIImage
    let highlights: [LessonCard.Highlight]
    var cornerRadius: CGFloat = 16

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ForEach(Array(highlights.enumerated()), id: \.offset) { index, h in
                        let rect = CGRect(x: h.x * geo.size.width, y: h.y * geo.size.height,
                                          width: h.w * geo.size.width, height: h.h * geo.size.height)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#D9B779"), lineWidth: 3)
                            .shadow(color: Color(hex: "#A87F40").opacity(0.6), radius: 4)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                        CalloutNumber(number: index + 1)
                            .position(badgePoint(for: rect, placement: h.badge, in: geo.size))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }

    private func badgePoint(for rect: CGRect, placement: String?, in size: CGSize) -> CGPoint {
        let gap: CGFloat = 14
        let point: CGPoint
        switch placement {
        case "top": point = CGPoint(x: rect.midX, y: rect.minY - gap)
        case "bottom": point = CGPoint(x: rect.midX, y: rect.maxY + gap)
        case "left": point = CGPoint(x: rect.minX - gap, y: rect.midY)
        case "right": point = CGPoint(x: rect.maxX + gap, y: rect.midY)
        case "insideRight": point = CGPoint(x: rect.maxX - gap - 2, y: rect.midY)
        default: point = CGPoint(x: rect.minX, y: rect.minY)
        }
        // Keep the whole badge on the picture.
        return CGPoint(x: min(max(point.x, 12), size.width - 12), y: min(max(point.y, 12), size.height - 12))
    }
}

struct CalloutNumber: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(hex: "#1E2B3A"))
            .frame(width: 22, height: 22)
            .background(Color(hex: "#D9B779"), in: Circle())
            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            .accessibilityHidden(true)
    }
}

/// Full-screen viewer with pinch-to-zoom and double-tap to zoom.
struct ZoomableScreenshot: View {
    let image: UIImage
    let highlights: [LessonCard.Highlight]
    let title: String

    @Environment(\.dismiss) var dismiss
    @State var scale: CGFloat = 1
    @State var lastScale: CGFloat = 1
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                AnnotatedScreenshot(image: image, highlights: highlights, cornerRadius: 8)
                    .padding()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in scale = min(max(lastScale * value.magnification, 1), 4) }
                            .onEnded { _ in
                                lastScale = scale
                                if scale == 1 { withAnimation { offset = .zero; lastOffset = .zero } }
                            }
                            .simultaneously(with: DragGesture()
                                .onChanged { value in
                                    guard scale > 1 else { return }
                                    offset = CGSize(width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height)
                                }
                                .onEnded { _ in lastOffset = offset })
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring) {
                            if scale > 1 {
                                scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
                            } else {
                                scale = 2.2; lastScale = 2.2
                            }
                        }
                    }
            }
            .background(Theme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
