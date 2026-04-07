import SwiftUI
import SwiftData
import Photos

// MARK: - Design Detail View

struct DesignDetailView: View {
    var suggestion: DesignSuggestion? = nil
    let colors: [NailColor]
    var selectedShape: NailShapeType = .rounded
    var sourceImage: UIImage? = nil

    @State private var animateIn = false
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteDesign]

    private var isFavorited: Bool {
        guard let suggestion else { return false }
        return favorites.contains { $0.title == suggestion.title }
    }

    var body: some View {
        ZStack {
            Color(hex: "FCFAF8").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Legacy design info (History / Favorites)
                    if let suggestion {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suggestion.emoji + " " + suggestion.title)
                                .font(.custom("CormorantGaramond-SemiBold", size: 28))
                                .foregroundColor(Color(hex: "2C2925"))
                            Text(suggestion.description)
                                .font(.custom("CormorantGaramond-Italic", size: 17))
                                .foregroundColor(Color(hex: "8E8A83"))
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.05), value: animateIn)
                    }

                    // Shop This Look — top of page
                    if !colors.isEmpty {
                        ShopThisLookCard(colors: colors)
                            .padding(.horizontal, 24)
                            .padding(.top, suggestion == nil ? 16 : 0)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    }

                    // Generate AI Nail Art button — bottom of page
                    if let sourceImage {
                        NavigationLink(destination: GenerateDesignView(
                            colors: colors,
                            selectedShape: selectedShape,
                            sourceImage: sourceImage
                        )) {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.sparkles")
                                    .font(.system(size: 16, weight: .light))
                                Text("Generate AI Nail Art")
                                    .font(.custom("CormorantGaramond-SemiBold", size: 18))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color(hex: "2C2925"))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color(hex: "2C2925").opacity(0.25), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle(suggestion?.title ?? "Your Design")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if suggestion != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(isFavorited ? Color(hex: "C9A84C") : Color(hex: "2C2925"))
                    }
                }
            }
        }
        .onAppear { animateIn = true }
    }

    private func toggleFavorite() {
        guard let suggestion else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let existing = favorites.first(where: { $0.title == suggestion.title }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteDesign(suggestion: suggestion, colors: colors))
        }
    }
}

// MARK: - Generate Design View

struct GenerateDesignView: View {
    let colors: [NailColor]
    let selectedShape: NailShapeType
    let sourceImage: UIImage

    @State private var generatedImage: UIImage? = nil
    @State private var isGenerating = false
    @State private var generationError = false
    @State private var emphasizedColorIDs: Set<UUID> = []
    @State private var selectedAddOn: DesignAddOn? = nil
    @State private var showSaveSuccess = false
    @State private var showPermissionError = false
    @State private var isSaving = false
    @State private var animateIn = false

    private var emphasizedColors: [NailColor] {
        colors.filter { emphasizedColorIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            Color(hex: "FCFAF8").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Generated image (shown after generation)
                    if let image = generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    } else if isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(Color(hex: "C9A84C"))
                                .scaleEffect(1.2)
                            Text("Creating your design...")
                                .font(.custom("CormorantGaramond-Italic", size: 16))
                                .foregroundColor(Color(hex: "8E8A83"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else if generationError {
                        VStack(spacing: 14) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color(hex: "C9A84C"))
                            Text("Couldn't generate your design")
                                .font(.custom("CormorantGaramond-SemiBold", size: 17))
                                .foregroundColor(Color(hex: "2C2925"))
                            Button(action: generateImage) {
                                Text("Try Again")
                                    .font(.custom("CormorantGaramond-SemiBold", size: 15))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "2C2925"))
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }

                    // Add Colors
                    colorRefinementSection
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)

                    // Design Add-ons
                    designAddOnSection
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.18), value: animateIn)

                    // Generate button
                    Button(action: generateImage) {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: generatedImage == nil ? "wand.and.sparkles" : "arrow.clockwise")
                                    .font(.system(size: 15, weight: .light))
                            }
                            Text(generatedImage == nil ? "Generate" : "Regenerate")
                                .font(.custom("CormorantGaramond-SemiBold", size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(isGenerating ? Color(hex: "C9A84C").opacity(0.6) : Color(hex: "C9A84C"))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.24), value: animateIn)

                    Spacer().frame(height: generatedImage != nil ? 110 : 40)
                }
            }

            // Save / Share bar — only when image is ready
            if generatedImage != nil {
                actionBar
            }
        }
        .navigationTitle("Generate Nail Art")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Add Colors Section

    @ViewBuilder
    private var colorRefinementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "C9A84C"))
                Text("Add Colors")
                    .font(.custom("CormorantGaramond-Bold", size: 20))
                    .foregroundColor(Color(hex: "2C2925"))
                Spacer()
                if !emphasizedColorIDs.isEmpty {
                    Text("\(emphasizedColorIDs.count) selected")
                        .font(.custom("CormorantGaramond-Italic", size: 13))
                        .foregroundColor(Color(hex: "C9A84C"))
                }
            }

            Text("Select colors from your photo to emphasize in the design.")
                .font(.custom("CormorantGaramond-Italic", size: 14))
                .foregroundColor(Color(hex: "8E8A83"))

            HStack(alignment: .top, spacing: 14) {
                ForEach(colors) { color in
                    let isSelected = emphasizedColorIDs.contains(color.id)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if isSelected {
                            emphasizedColorIDs.remove(color.id)
                        } else {
                            emphasizedColorIDs.insert(color.id)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 46, height: 46)
                                    .shadow(color: color.swiftUIColor.opacity(0.35), radius: 5, x: 0, y: 2)
                                    .overlay(
                                        Circle().stroke(
                                            isSelected ? Color(hex: "C9A84C") : Color.white,
                                            lineWidth: isSelected ? 3 : 2
                                        )
                                    )
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            Text(color.name)
                                .font(.custom("CormorantGaramond-Regular", size: 10))
                                .foregroundColor(isSelected ? Color(hex: "C9A84C") : Color(hex: "8E8A83"))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.8)
                                .frame(width: 52)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // MARK: - Design Add-On Section

    @ViewBuilder
    private var designAddOnSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "C9A84C"))
                Text("Design Add-ons")
                    .font(.custom("CormorantGaramond-Bold", size: 20))
                    .foregroundColor(Color(hex: "2C2925"))
                Spacer()
                if selectedAddOn != nil {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedAddOn = nil
                    } label: {
                        Text("Clear")
                            .font(.custom("CormorantGaramond-Italic", size: 13))
                            .foregroundColor(Color(hex: "8E8A83"))
                    }
                }
            }

            Text("Choose an optional finish to apply to your design.")
                .font(.custom("CormorantGaramond-Italic", size: 14))
                .foregroundColor(Color(hex: "8E8A83"))

            let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(DesignAddOn.allCases, id: \.rawValue) { addOn in
                    let isSelected = selectedAddOn == addOn
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedAddOn = isSelected ? nil : addOn
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(addOn.emoji)
                                .font(.system(size: 24))
                            Text(addOn.displayName)
                                .font(.custom("CormorantGaramond-SemiBold", size: 15))
                                .foregroundColor(isSelected ? Color(hex: "C9A84C") : Color(hex: "2C2925"))
                            Text(addOn.description)
                                .font(.custom("CormorantGaramond-Italic", size: 12))
                                .foregroundColor(Color(hex: "8E8A83"))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(isSelected ? Color(hex: "C9A84C").opacity(0.06) : Color(hex: "F9F7F4"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color(hex: "C9A84C") : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.18), value: isSelected)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedAddOn == nil)
    }

    // MARK: - Action Bar

    @ViewBuilder
    private var actionBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
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
        }
    }

    // MARK: - Actions

    private func generateImage() {
        guard !isGenerating else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isGenerating = true
        generationError = false
        Task {
            do {
                generatedImage = try await GeminiService().generatePhotoInspiredImage(
                    from: sourceImage,
                    colors: colors,
                    shape: selectedShape,
                    emphasizedColors: emphasizedColors,
                    addOn: selectedAddOn
                )
            } catch {
                print("[Generate] Failed: \(error)")
                generationError = true
            }
            isGenerating = false
        }
    }

    private func saveDesign() {
        guard let image = generatedImage else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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

    private func shareDesign() {
        guard let image = generatedImage else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController?.present(vc, animated: true)
    }
}

// MARK: - Shop This Look Card

struct ShopThisLookCard: View {
    let colors: [NailColor]

    private var matches: [(NailColor, [NailPolishProduct])] {
        colors.map { color in
            (color, NailPolishProduct.matches(for: color.hex, count: 2))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "bag")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color(hex: "C9A84C"))
                Text("Shop This Look")
                    .font(.custom("CormorantGaramond-Bold", size: 20))
                    .foregroundColor(Color(hex: "2C2925"))
                Spacer()
                Text("via Amazon")
                    .font(.custom("CormorantGaramond-Italic", size: 12))
                    .foregroundColor(Color(hex: "8E8A83"))
            }

            Text("Closest matching polishes for your colors.")
                .font(.custom("CormorantGaramond-Italic", size: 14))
                .foregroundColor(Color(hex: "8E8A83"))

            ForEach(matches, id: \.0.id) { color, products in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .shadow(color: color.swiftUIColor.opacity(0.3), radius: 3, x: 0, y: 1)
                        Text(color.name)
                            .font(.custom("CormorantGaramond-SemiBold", size: 14))
                            .foregroundColor(Color(hex: "2C2925"))
                    }

                    VStack(spacing: 8) {
                        ForEach(products) { product in
                            Link(destination: product.affiliateURL) {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(product.swiftUIColor)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: product.swiftUIColor.opacity(0.3), radius: 4, x: 0, y: 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.brand)
                                            .font(.custom("CormorantGaramond-Regular", size: 11))
                                            .foregroundColor(Color(hex: "8E8A83"))
                                        Text(product.name)
                                            .font(.custom("CormorantGaramond-SemiBold", size: 15))
                                            .foregroundColor(Color(hex: "2C2925"))
                                    }

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Text("Buy")
                                            .font(.custom("CormorantGaramond-SemiBold", size: 13))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(Color(hex: "C9A84C"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "C9A84C").opacity(0.08))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color(hex: "C9A84C").opacity(0.3), lineWidth: 1))
                                }
                                .padding(12)
                                .background(Color(hex: "F9F7F4"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }

                if color.id != matches.last?.0.id {
                    Divider().opacity(0.4)
                }
            }

            Text("As an Amazon Associate I earn from qualifying purchases.")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8E8A83").opacity(0.7))
                .padding(.top, 4)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Nail Shape (used by ColorSelectionView)

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
