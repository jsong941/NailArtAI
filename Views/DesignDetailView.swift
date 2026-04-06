import SwiftUI
import SwiftData
import Photos

struct DesignDetailView: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]
    var selectedShape: NailShapeType = .rounded

    @State private var activeSuggestion: DesignSuggestion
    @State private var activePattern: NailPattern
    @State private var activeColors: [NailColor]
    @State private var isRegenerating = false
    @State private var animateIn = false
    @State private var showSaveSuccess = false
    @State private var showPermissionError = false
    @State private var isSaving = false
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteDesign]

    init(suggestion: DesignSuggestion, colors: [NailColor], selectedShape: NailShapeType = .rounded) {
        self.suggestion = suggestion
        self.colors = colors
        self.selectedShape = selectedShape
        _activeSuggestion = State(initialValue: suggestion)
        _activePattern = State(initialValue: suggestion.pattern)
        _activeColors = State(initialValue: colors)
        _isRegenerating = State(initialValue: false)
    }

    private var isFavorited: Bool {
        favorites.contains { $0.title == activeSuggestion.title }
    }

    var body: some View {
        ZStack {
            Color(hex: "FCFAF8")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Nail preview with color swap
                    NailPreviewCard(
                        suggestion: activeSuggestion,
                        colors: activeColors,
                        patternOverride: activePattern,
                        selectedShape: selectedShape,
                        onTapColor: { tappedIndex in
                            guard activeColors.count > 1 else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            var reordered = activeColors
                            let tapped = reordered.remove(at: tappedIndex)
                            reordered.insert(tapped, at: 0)
                            activeColors = reordered
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.95)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.05), value: animateIn)

                    // Pattern picker
                    PatternPickerRow(activePattern: $activePattern)
                        .padding(.horizontal, 20)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)

                    // Design title + description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeSuggestion.title)
                            .font(.custom("CormorantGaramond-SemiBold", size: 26))
                            .foregroundColor(Color(hex: "2C2925"))
                        Text(activeSuggestion.description)
                            .font(.custom("CormorantGaramond-Italic", size: 16))
                            .foregroundColor(Color(hex: "8E8A83"))
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)

                    // Compact tip card
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            Image(systemName: "lightbulb")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "C9A84C"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pro Tip")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(Color(hex: "2C2925"))
                            Text("Apply a base coat, use thin layers, and finish with a glossy top coat to protect your design.")
                                .font(.custom("CormorantGaramond-Italic", size: 15))
                                .foregroundColor(Color(hex: "8E8A83"))
                                .lineSpacing(3)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "F3EFEA"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.03), lineWidth: 1))
                    .padding(.horizontal, 20)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.28), value: animateIn)

                    Spacer().frame(height: 110)
                }
            }

            // Save + Share action bar pinned to bottom
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    // Save — wide
                    Button { saveDesign() } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().tint(Color(hex: "2C2925")).scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundColor(Color(hex: "C9A84C"))
                            }
                            Text("Save Design")
                                .font(.custom("CormorantGaramond-SemiBold", size: 17))
                                .foregroundColor(Color(hex: "2C2925"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    }
                    .disabled(isSaving)

                    // Share — icon-only square
                    Button { shareDesign() } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .light))
                            .foregroundColor(.white)
                            .frame(width: 58, height: 58)
                            .background(Color(hex: "2C2925"))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FCFAF8").opacity(0), Color(hex: "FCFAF8")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 120).ignoresSafeArea()
                )
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.35), value: animateIn)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isRegenerating {
                    ProgressView()
                        .tint(Color(hex: "2C2925"))
                        .scaleEffect(0.8)
                } else {
                    Button(action: regenerate) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(Color(hex: "2C2925"))
                    }
                }
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(isFavorited ? Color(hex: "C9A84C") : Color(hex: "2C2925"))
                }
            }
        }
        .onAppear { animateIn = true }
        .alert("Design Saved", isPresented: $showSaveSuccess) {
            Button("Done", role: .cancel) {}
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

    // MARK: - Regenerate

    private func regenerate() {
        guard !isRegenerating else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isRegenerating = true
        Task {
            do {
                let newSuggestion = try await GeminiService().regenerateSingleDesign(for: activeColors)
                activeSuggestion = newSuggestion
                activePattern = newSuggestion.pattern
            } catch {
                // silently keep current design on failure
            }
            isRegenerating = false
        }
    }

    // MARK: - Favorite

    private func toggleFavorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let existing = favorites.first(where: { $0.title == activeSuggestion.title }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteDesign(suggestion: activeSuggestion, colors: activeColors))
        }
    }

    // MARK: - Save

    private func saveDesign() {
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let refined = DesignSuggestion(emoji: activeSuggestion.emoji, title: activeSuggestion.title, description: activeSuggestion.description, pattern: activePattern)
        let card = DesignShareCard(suggestion: refined, colors: activeColors, shapeType: selectedShape)
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
        let refined = DesignSuggestion(emoji: activeSuggestion.emoji, title: activeSuggestion.title, description: activeSuggestion.description, pattern: activePattern)
        let card = DesignShareCard(suggestion: refined, colors: activeColors, shapeType: selectedShape)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController?.present(vc, animated: true)
    }
}

// MARK: - Pattern Picker Row

struct PatternPickerRow: View {
    @Binding var activePattern: NailPattern

    private let patterns: [(NailPattern, String, String)] = [
        (.solid,    "Solid",   "circle.fill"),
        (.ombre,    "Ombré",   "circle.lefthalf.filled"),
        (.french,   "French",  "circle.tophalf.filled"),
        (.glitter,  "Glitter", "sparkles"),
        (.abstract, "Abstract","scribble.variable")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(patterns, id: \.0.rawValue) { pattern, label, icon in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        activePattern = pattern
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: icon)
                                .font(.system(size: 11, weight: .light))
                            Text(label)
                                .font(.custom("CormorantGaramond-SemiBold", size: 14))
                        }
                        .foregroundColor(activePattern == pattern ? .white : Color(hex: "2C2925"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(activePattern == pattern ? Color(hex: "C9A84C") : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                            activePattern == pattern ? Color.clear : Color.black.opacity(0.07),
                            lineWidth: 1
                        ))
                        .shadow(
                            color: activePattern == pattern ? Color(hex: "C9A84C").opacity(0.25) : Color.clear,
                            radius: 6, x: 0, y: 3
                        )
                    }
                    .animation(.easeInOut(duration: 0.18), value: activePattern)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Nail Preview Card

struct NailPreviewCard: View {
    let suggestion: DesignSuggestion
    let colors: [NailColor]
    var patternOverride: NailPattern
    let selectedShape: NailShapeType
    var onTapColor: ((Int) -> Void)? = nil

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
                        pattern: patternOverride,
                        shapeType: selectedShape
                    )
                }
            }
            .padding(.vertical, 8)

            // Color swatches — tappable to reorder (primary color gets gold ring)
            if colors.count > 1 {
                HStack(spacing: 10) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                        Button {
                            onTapColor?(index)
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle().stroke(
                                            index == 0 ? Color(hex: "C9A84C") : Color(hex: "E5E5EA"),
                                            lineWidth: index == 0 ? 2.5 : 1.5
                                        )
                                    )
                                    .shadow(color: color.swiftUIColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                Text(index == 0 ? "Primary" : "Secondary")
                                    .font(.custom("CormorantGaramond-Regular", size: 9))
                                    .foregroundColor(index == 0 ? Color(hex: "C9A84C") : Color(hex: "8E8E93"))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Text("Tap to swap")
                        .font(.custom("CormorantGaramond-Italic", size: 11))
                        .foregroundColor(Color(hex: "C9A84C").opacity(0.7))
                }
                .padding(.top, 2)
            }

            Text(suggestion.title)
                .font(.custom("CormorantGaramond-Italic", size: 14))
                .foregroundColor(Color(hex: "8E8E93"))
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 6)
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
