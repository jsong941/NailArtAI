import SwiftUI
import SwiftData
import Photos

struct DesignDetailView: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]
    var selectedShape: NailShapeType = .rounded
    @State private var animateIn = false
    @State private var showSaveSuccess = false
    @State private var showPermissionError = false
    @State private var isSaving = false
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteDesign]

    private var isFavorited: Bool {
        favorites.contains { $0.title == suggestion.title }
    }

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // Nail preview
                    NailPreviewCard(suggestion: suggestion, colors: colors, selectedShape: selectedShape)
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
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: animateIn)

                    Spacer().frame(height: 110)
                }
            }

            // Save + Share action bar pinned to bottom
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button { saveDesign() } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text("Save")
                                .font(.custom("CormorantGaramond-SemiBold", size: 17))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient(colors: [Color(hex: "C9A84C"), Color(hex: "B8860B")], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSaving)

                    Button { shareDesign() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Share")
                                .font(.custom("CormorantGaramond-SemiBold", size: 17))
                        }
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(hex: "E5E5EA"), lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .background(
                    LinearGradient(colors: [Color(hex: "FAFAF8").opacity(0), Color(hex: "FAFAF8")], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120).ignoresSafeArea()
                )
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: animateIn)
            }
        }
        .navigationTitle(suggestion.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "C9A84C"))
                }
            }
        }
        .onAppear { animateIn = true }
        .alert("Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your design has been saved to your photo library.")
        }
        .alert("Permission Needed", isPresented: $showPermissionError) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow photo library access in Settings to save designs.")
        }
    }

    // MARK: - Favorite
    private func toggleFavorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let existing = favorites.first(where: { $0.title == suggestion.title }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteDesign(suggestion: suggestion, colors: colors))
        }
    }

    // MARK: - Save
    private func saveDesign() {
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let card = DesignShareCard(suggestion: suggestion, colors: colors, shapeType: selectedShape)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { isSaving = false; return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                isSaving = false
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showSaveSuccess = true
                default:
                    showPermissionError = true
                }
            }
        }
    }

    // MARK: - Share
    private func shareDesign() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let card = DesignShareCard(suggestion: suggestion, colors: colors, shapeType: selectedShape)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController?.present(vc, animated: true)
    }
}

// MARK: - Nail Preview Card

struct NailPreviewCard: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]
    let selectedShape: NailShapeType

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

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<5, id: \.self) { index in
                    NailView(
                        color: colors[index % colors.count].swiftUIColor,
                        secondaryColor: colors[(index + 1) % colors.count].swiftUIColor,
                        height: nailHeight(for: index),
                        label: colors[index % colors.count].name,
                        pattern: suggestion.pattern,
                        shapeType: selectedShape
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

    private func nailHeight(for index: Int) -> CGFloat {
        [62, 70, 74, 72, 58][index]
    }
}

// MARK: - Single Nail

struct NailView: View {
    let color: Color
    let secondaryColor: Color
    let height: CGFloat
    let label: String
    let pattern: NailPattern
    let shapeType: NailShapeType

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                nailFill
                    .frame(width: 36, height: height)
                    .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)

                NailShape(shapeType: shapeType)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.3), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: height)

                if pattern == .glitter {
                    NailShape(shapeType: shapeType)
                        .fill(Color.clear)
                        .frame(width: 36, height: height)
                        .overlay(
                            GeometryReader { geo in
                                ForEach(glitterPositions, id: \.x) { pos in
                                    Circle()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(width: pos.size, height: pos.size)
                                        .position(x: geo.size.width * pos.x, y: geo.size.height * pos.y)
                                }
                            }
                            .clipShape(NailShape(shapeType: shapeType))
                        )
                }

                if pattern == .french {
                    VStack(spacing: 0) {
                        NailShape(shapeType: shapeType)
                            .fill(secondaryColor.opacity(0.85))
                            .frame(width: 36, height: height * 0.28)
                        Spacer()
                    }
                    .frame(width: 36, height: height)
                    .clipShape(NailShape(shapeType: shapeType))
                }
            }

            Text(label)
                .font(.custom("CormorantGaramond-Regular", size: 9))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineLimit(1)
                .frame(width: 40)
        }
    }

    @ViewBuilder
    private var nailFill: some View {
        switch pattern {
        case .ombre:
            NailShape(shapeType: shapeType)
                .fill(LinearGradient(colors: [color, secondaryColor], startPoint: .top, endPoint: .bottom))
        case .abstract:
            NailShape(shapeType: shapeType)
                .fill(LinearGradient(colors: [color, secondaryColor, color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
        default:
            NailShape(shapeType: shapeType).fill(color)
        }
    }

    private let glitterPositions: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.2, 0.2, 3), (0.7, 0.15, 2), (0.5, 0.4, 4),
        (0.3, 0.6, 2), (0.8, 0.5, 3), (0.15, 0.75, 2),
        (0.6, 0.75, 3), (0.45, 0.88, 2), (0.85, 0.82, 2)
    ]
}

// MARK: - Nail Shape

struct NailShape: Shape {
    var shapeType: NailShapeType = .rounded

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        var path = Path()

        switch shapeType {

        case .rounded:
            let r = cx
            path.move(to: CGPoint(x: 0, y: r))
            path.addArc(center: CGPoint(x: cx, y: r), radius: r,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.closeSubpath()

        case .almond:
            path.move(to: CGPoint(x: 0, y: h))
            path.addCurve(to: CGPoint(x: cx, y: h * 0.04),
                          control1: CGPoint(x: 0, y: h * 0.35),
                          control2: CGPoint(x: cx * 0.2, y: h * 0.04))
            path.addCurve(to: CGPoint(x: w, y: h),
                          control1: CGPoint(x: cx * 1.8, y: h * 0.04),
                          control2: CGPoint(x: w, y: h * 0.35))
            path.closeSubpath()

        case .stiletto:
            path.move(to: CGPoint(x: 0, y: h))
            path.addCurve(to: CGPoint(x: cx, y: 0),
                          control1: CGPoint(x: 0, y: h * 0.55),
                          control2: CGPoint(x: cx * 0.35, y: h * 0.05))
            path.addCurve(to: CGPoint(x: w, y: h),
                          control1: CGPoint(x: cx * 1.65, y: h * 0.05),
                          control2: CGPoint(x: w, y: h * 0.55))
            path.closeSubpath()

        case .flare:
            let inset = w * 0.18
            path.move(to: CGPoint(x: inset, y: h))
            path.addLine(to: CGPoint(x: 0, y: h * 0.25))
            path.addQuadCurve(to: CGPoint(x: w, y: h * 0.25),
                              control: CGPoint(x: cx, y: -h * 0.08))
            path.addLine(to: CGPoint(x: w - inset, y: h))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Share Card

struct DesignShareCard: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]
    var shapeType: NailShapeType = .rounded

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<5, id: \.self) { index in
                        NailView(
                            color: colors[index % colors.count].swiftUIColor,
                            secondaryColor: colors[(index + 1) % colors.count].swiftUIColor,
                            height: [62, 70, 74, 72, 58][index],
                            label: "",
                            pattern: suggestion.pattern,
                            shapeType: shapeType
                        )
                    }
                }
                .padding(.vertical, 8)

                Text(suggestion.emoji + " " + suggestion.title)
                    .font(.custom("CormorantGaramond-Bold", size: 22))
                    .foregroundColor(Color(hex: "1C1C1E"))
            }
            .padding(24)
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(hex: "C9A84C").opacity(0.3))
                .frame(height: 1)

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "C9A84C"))
                Text("NailArtAI")
                    .font(.custom("CormorantGaramond-SemiBold", size: 14))
                    .foregroundColor(Color(hex: "C9A84C"))
            }
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 6)
        .frame(width: 340)
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
