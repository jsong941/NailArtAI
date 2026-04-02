import SwiftUI

/// Programmatic app icon — preview at 1024×1024 in Xcode canvas.
/// To export: run the app on simulator, screenshot the preview, or use
/// Xcode's canvas "Export" to save as PNG for Assets.xcassets → AppIcon.
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "FEFCF7"), Color(hex: "F5EDD8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Outer soft glow ring
            Circle()
                .fill(Color(hex: "C9A84C").opacity(0.08))
                .frame(width: 620, height: 620)

            Circle()
                .fill(Color(hex: "C9A84C").opacity(0.05))
                .frame(width: 760, height: 760)

            // Nail shape
            NailShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "DDB85C"), Color(hex: "C9A84C"), Color(hex: "A07830")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 210, height: 310)
                .shadow(color: Color(hex: "C9A84C").opacity(0.45), radius: 40, x: 0, y: 16)
                .offset(y: -30)
                .overlay(
                    // Shine
                    NailShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: 210, height: 310)
                        .offset(y: -30)
                )

            // Sparkles
            SparkleIcon(size: 22).offset(x: -170, y: -210)
            SparkleIcon(size: 14).offset(x: 195, y: -185)
            SparkleIcon(size: 18).offset(x: 210, y: 60)
            SparkleIcon(size: 12).offset(x: -210, y: 80)
            SparkleIcon(size: 10).offset(x: 100, y: -270)
            SparkleIcon(size: 8).offset(x: -100, y: 240)

            // "AI" label beneath nail
            Text("AI")
                .font(.custom("CormorantGaramond-Bold", size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "C9A84C"), Color(hex: "9A7030")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 230)
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 0)) // iOS masks corners itself
    }
}

// MARK: - Sparkle
private struct SparkleIcon: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .light))
            .foregroundColor(Color(hex: "C9A84C").opacity(0.6))
    }
}

#Preview("App Icon 1024×1024") {
    AppIconView()
        .frame(width: 1024, height: 1024)
        .scaleEffect(0.35) // fits preview pane; actual export should be full size
        .frame(width: 358, height: 358)
        .clipShape(RoundedRectangle(cornerRadius: 80))
        .shadow(radius: 20)
        .padding()
}
