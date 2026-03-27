import SwiftUI

struct DesignDetailView: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // Nail preview
                    NailPreviewCard(suggestion: suggestion, colors: colors)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.95)
                        .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.05), value: animateIn)

                    // Gold divider
                    Rectangle()
                        .fill(Color(hex: "C9A84C").opacity(0.4))
                        .frame(width: 48, height: 1.5)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)

                    // Description card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 7) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "C9A84C"))
                            Text("Design Description")
                                .font(.custom("CormorantGaramond-Bold", size: 20))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                        Text(suggestion.description)
                            .font(.custom("CormorantGaramond-Regular", size: 18))
                            .foregroundColor(Color(hex: "3C3C3E"))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: animateIn)

                    // Tips card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 7) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "C9A84C"))
                            Text("Pro Tips")
                                .font(.custom("CormorantGaramond-Bold", size: 20))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            TipRow(text: "Apply a base coat to help the colors pop and last longer.")
                            TipRow(text: "Use thin layers and let each coat dry fully before the next.")
                            TipRow(text: "Finish with a glossy top coat to seal and protect your design.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.35), value: animateIn)

                    Spacer().frame(height: 32)
                }
            }
        }
        .navigationTitle(suggestion.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animateIn = true }
    }
}

// MARK: - Nail Preview Card
struct NailPreviewCard: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 7) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "C9A84C"))
                Text("Nail Preview")
                    .font(.custom("CormorantGaramond-Bold", size: 20))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Spacer()
            }

            // 5 nails in a hand-like arrangement
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<5, id: \.self) { index in
                    NailView(
                        color: colors.indices.contains(index) ? colors[index].swiftUIColor : Color(hex: "F5F0E8"),
                        height: nailHeight(for: index),
                        label: colors.indices.contains(index) ? colors[index].name : ""
                    )
                }
            }
            .padding(.vertical, 8)

            Text(suggestion.title)
                .font(.custom("CormorantGaramond-Italic", size: 14))
                .foregroundColor(Color(hex: "8E8E93"))
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // Mimic natural finger height variation (ring finger tallest)
    private func nailHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [62, 70, 74, 72, 58]
        return heights[index]
    }
}

// MARK: - Single Nail
struct NailView: View {
    let color: Color
    let height: CGFloat
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Nail body
                NailShape()
                    .fill(color)
                    .frame(width: 36, height: height)
                    .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)

                // Shine overlay
                NailShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: height)
            }

            Text(label)
                .font(.custom("CormorantGaramond-Regular", size: 9))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineLimit(1)
                .frame(width: 40)
        }
    }
}

// MARK: - Nail Shape
struct NailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r = w / 2

        // Rounded top, straight sides, flat bottom
        path.move(to: CGPoint(x: 0, y: r))
        path.addArc(
            center: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(hex: "C9A84C"))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.custom("CormorantGaramond-Italic", size: 15))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(3)
        }
    }
}
