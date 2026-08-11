import SwiftUI
import SwiftData
import Photos
import Combine

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
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Legacy design info (History / Favorites)
                    if let suggestion {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suggestion.emoji + " " + suggestion.title)
                                .font(.custom("CormorantGaramond-SemiBold", size: 28))
                                .foregroundColor(Color.textPrimary)
                            Text(suggestion.description)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
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
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color.textPrimary.opacity(0.25), radius: 10, x: 0, y: 4)
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
                            .foregroundColor(isFavorited ? Color.appAccent : Color.textPrimary)
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

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.modelContext) private var modelContext

    @State private var generatedImage: UIImage? = nil
    @State private var isGenerating = false
    @State private var generationError = false
    @State private var generationErrorMessage: String? = nil
    @State private var emphasizedColorIDs: Set<UUID> = []
    @State private var selectedAddOn: DesignAddOn? = nil
    @State private var frenchTipColor: NailColor? = nil
    @State private var gemStoneStyle: GemStoneStyle? = nil
    @State private var finishStyle: FinishStyle? = nil
    @State private var showSaveSuccess = false
    @State private var showPermissionError = false
    @State private var showFavoriteSuccess = false
    @State private var isFavorited = false
    @State private var isSaving = false
    @State private var animateIn = false
    @State private var showPaywall = false
    @State private var loadingStage = 0
    @State private var pulseIcon = false

    private let loadingMessages = [
        "Studying your photo…",
        "Mixing your palette…",
        "Painting each nail…",
        "Perfecting the details…",
        "Adding the final gloss…"
    ]
    private let loadingTimer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    private var emphasizedColors: [NailColor] {
        colors.filter { emphasizedColorIDs.contains($0.id) }
    }

    private var effectiveAddOnNote: String? {
        guard let addOn = selectedAddOn else { return nil }
        switch addOn {
        case .frenchTip:
            if let color = frenchTipColor {
                return "Add elegant french tips using \(color.name) (#\(color.hex)) as the tip color on a nude/natural base."
            }
            return "Add classic elegant french tips on a nude/natural base."
        case .solidColor:
            return "Keep the design clean and minimal with a smooth solid color application — no patterns or embellishments."
        case .gemStone:
            switch gemStoneStyle {
            case .minimalism:
                return "Add minimal crystal rhinestone embellishments — no more than 3 gems per finger — for subtle, understated luxury."
            case .maximalism:
                return "Add full maximalist crystal and gemstone coverage across all nails for a bold, dramatic statement look."
            case nil:
                return "Add decorative crystal rhinestone embellishments on accent nails for a luxurious look."
            }
        case .finish:
            switch finishStyle {
            case .chromePowder:
                return "Apply a chrome mirror powder finish for a glazed, ultra-reflective metallic effect."
            case .glitters:
                return "Cover the nails entirely in dense, holographic fine glitter — iridescent rainbow sparkle packed wall-to-wall with no bare nail visible, catching light in multiple colors. The glitter should look lavishly full and multidimensional, similar to Holo Taco-style holographic glitter nails."
            case .mirrorPowder:
                return "Apply an ultra-high-shine mirror powder finish for an intense, glass-like reflective effect."
            case .catEye:
                let baseColor = emphasizedColors.first ?? colors.first
                let baseName = baseColor?.name ?? "deep jewel-toned"
                return "Magnetic cat eye gel nails with \(baseName) as the base. Exactly one single streak of light per nail — no multiple highlights, no split streaks. The streak emerges organically from within the nail, a soft luminous glow that fades seamlessly into the base with no visible edge or border. The streak is a lighter reflection of the same \(baseName) tone, like light refracting through deep glass. Glossy, gel-like finish."
            case nil:
                return "Apply a special finish to the nails for added visual interest."
            }
        }
    }

    private func selectAddOn(_ addOn: DesignAddOn) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if selectedAddOn == addOn {
            selectedAddOn = nil
        } else {
            selectedAddOn = addOn
        }
        frenchTipColor = nil
        gemStoneStyle = nil
        finishStyle = nil
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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
                        generationProgressCard
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    } else if generationError {
                        VStack(spacing: 14) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color.appAccent)
                            Text(generationErrorMessage ?? "Couldn't generate your design")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            Button(action: generateImage) {
                                Text("Try Again")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 10)
                                    .background(Color.textPrimary)
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

                    // Design Add-ons
                    designAddOnSection
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.18), value: animateIn)

                    // Generations remaining warning (free users only)
                    if !subscriptionManager.isSubscribed {
                        let remaining = subscriptionManager.generationsRemaining
                        let isOut = remaining == 0
                        let isLow = remaining == 1
                        HStack(spacing: 10) {
                            Image(systemName: isOut ? "exclamationmark.circle.fill" : "info.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(isOut ? .red : isLow ? Color.appAccent : Color.textSecondary)
                            Text(isOut
                                 ? "No generations left — upgrade to keep creating"
                                 : "\(remaining) free generation\(remaining == 1 ? "" : "s") left")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isOut ? .red : isLow ? Color.appAccent : Color.textPrimary)
                            Spacer()
                            if !isOut {
                                Button {
                                    showPaywall = true
                                } label: {
                                    Text("Upgrade")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.appAccent)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(12)
                        .background(isOut ? Color.red.opacity(0.07) : isLow ? Color.appAccent.opacity(0.08) : Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isOut ? Color.red.opacity(0.2) : isLow ? Color.appAccent.opacity(0.25) : Color.clear, lineWidth: 1))
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.22), value: animateIn)
                    }

                    // Generate button
                    Button(action: generateImage) {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: generatedImage == nil ? "wand.and.sparkles" : "arrow.clockwise")
                                    .font(.system(size: 15, weight: .light))
                            }
                            Text(subscriptionManager.generationsRemaining == 0 && !subscriptionManager.isSubscribed
                                 ? "Keep Designing!"
                                 : generatedImage == nil ? "Generate" : "Regenerate")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(isGenerating ? Color.appAccent.opacity(0.6) : Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 4)
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
        .onReceive(loadingTimer) { _ in
            guard isGenerating else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                loadingStage = min(loadingStage + 1, loadingMessages.count - 1)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .alert("Design Saved", isPresented: $showSaveSuccess) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Your design has been saved to your photo library.")
        }
        .alert("Added to Favorites", isPresented: $showFavoriteSuccess) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Your design has been saved to Favorites.")
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

    // MARK: - Generation Progress Card

    @ViewBuilder
    private var generationProgressCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentSoft)
                    .frame(width: 72, height: 72)
                    .scaleEffect(pulseIcon ? 1.12 : 0.94)
                Image(systemName: "wand.and.sparkles")
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(Color.appAccent)
                    .rotationEffect(.degrees(pulseIcon ? 8 : -8))
            }
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulseIcon)

            VStack(spacing: 8) {
                Text(loadingMessages[loadingStage])
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                    .id(loadingStage)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                Text("This can take up to a minute")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }

            HStack(spacing: 6) {
                ForEach(loadingMessages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= loadingStage ? Color.appAccent : Color.divider)
                        .frame(width: i == loadingStage ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: loadingStage)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        .shimmer()
        .onAppear { pulseIcon = true }
        .onDisappear { pulseIcon = false }
    }

    // MARK: - Add Colors Section

    @ViewBuilder
    private var colorRefinementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color.appAccent)
                Text("Add Colors")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                if !emphasizedColorIDs.isEmpty {
                    Text("\(emphasizedColorIDs.count) selected")
                        .font(.system(size: 11))
                        .foregroundColor(Color.appAccent)
                }
            }

            Text("Select colors from your photo to emphasize in the design.")
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)

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
                                            isSelected ? Color.appAccent : Color.white,
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
                                .font(.system(size: 11))
                                .foregroundColor(isSelected ? Color.appAccent : Color.textSecondary)
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
                    .foregroundColor(Color.appAccent)
                Text("Design Add-ons")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                if selectedAddOn != nil {
                    Button {
                        selectAddOn(selectedAddOn!)
                    } label: {
                        Text("Clear")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }

            Text("Choose an optional enhancement for your design.")
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)

            VStack(spacing: 8) {
                ForEach(DesignAddOn.allCases, id: \.rawValue) { addOn in
                    addOnRow(addOn)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private func addOnRow(_ addOn: DesignAddOn) -> some View {
        let isSelected = selectedAddOn == addOn
        VStack(spacing: 0) {
            Button { selectAddOn(addOn) } label: {
                HStack(spacing: 12) {
                    Text(addOn.emoji)
                        .font(.system(size: 20))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(addOn.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSelected ? Color.appAccent : Color.textPrimary)
                        Text(addOn.description)
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                    }
                    Spacer()
                    if addOn.hasSubmenu {
                        Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    } else if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.appAccent)
                    }
                }
                .padding(14)
                .background(isSelected ? Color.appAccent.opacity(0.06) : Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.18), value: isSelected)

            if isSelected && addOn.hasSubmenu {
                addOnSubmenu(addOn)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
    }

    @ViewBuilder
    private func addOnSubmenu(_ addOn: DesignAddOn) -> some View {
        switch addOn {
        case .frenchTip:
            VStack(alignment: .leading, spacing: 8) {
                Text("Tip color — nude base by default")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
                HStack(alignment: .top, spacing: 14) {
                    ForEach(colors) { color in
                        let isChosen = frenchTipColor?.id == color.id
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            frenchTipColor = isChosen ? nil : color
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(color.swiftUIColor)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: color.swiftUIColor.opacity(0.35), radius: 4, x: 0, y: 2)
                                        .overlay(Circle().stroke(isChosen ? Color.appAccent : Color.white, lineWidth: isChosen ? 3 : 2))
                                    if isChosen {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Text(color.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(isChosen ? Color.appAccent : Color.textSecondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 48)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

        case .gemStone:
            HStack(spacing: 10) {
                ForEach(GemStoneStyle.allCases, id: \.rawValue) { style in
                    let isChosen = gemStoneStyle == style
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        gemStoneStyle = isChosen ? nil : style
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(style.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isChosen ? Color.appAccent : Color.textPrimary)
                            Text(style.description)
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(isChosen ? Color.appAccent.opacity(0.08) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isChosen ? Color.appAccent : Color.divider, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isChosen)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

        case .finish:
            let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(FinishStyle.allCases, id: \.rawValue) { style in
                    let isChosen = finishStyle == style
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        finishStyle = isChosen ? nil : style
                    } label: {
                        Text(style.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isChosen ? Color.appAccent : Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isChosen ? Color.appAccent.opacity(0.08) : Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isChosen ? Color.appAccent : Color.divider, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isChosen)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)

        default:
            EmptyView()
        }
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
                            ProgressView().tint(Color.textPrimary).scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 15, weight: .light))
                                .foregroundColor(Color.appAccent)
                        }
                        Text("Save Design")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                }
                .disabled(isSaving)

                Button { saveFavorite() } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(isFavorited ? Color.appAccent : .white)
                        .frame(width: 58, height: 58)
                        .background(isFavorited ? Color.white : Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isFavorited ? Color.appAccent.opacity(0.3) : Color.clear, lineWidth: 1))
                }
                .disabled(isFavorited)

                Button { shareDesign() } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(Color.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .background(
                LinearGradient(
                    colors: [Color.appBackground.opacity(0), Color.appBackground],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 120).ignoresSafeArea()
            )
        }
    }

    // MARK: - Actions

    private func generateImage() {
        guard !isGenerating else { return }
        guard subscriptionManager.canGenerate else {
            showPaywall = true
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isGenerating = true
        generationError = false
        generationErrorMessage = nil
        loadingStage = 0
        Task {
            do {
                let image = try await GeminiService().generatePhotoInspiredImage(
                    from: sourceImage,
                    colors: colors,
                    shape: selectedShape,
                    emphasizedColors: emphasizedColors,
                    addOnNote: effectiveAddOnNote
                )
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    generatedImage = image
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                subscriptionManager.recordGeneration()
                isFavorited = false
            } catch {
                print("[Generate] Failed: \(error)")
                generationErrorMessage = (error as? GeminiError)?.errorDescription
                generationError = true
            }
            isGenerating = false
        }
    }

    private func saveFavorite() {
        guard let image = generatedImage else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let imageData = image.jpegData(compressionQuality: 0.8)
        let suggestion = DesignSuggestion(
            emoji: selectedAddOn?.emoji ?? "✨",
            title: selectedAddOn?.displayName ?? "AI Nail Art",
            description: effectiveAddOnNote ?? "AI-generated nail art design",
            pattern: .abstract
        )
        let favorite = FavoriteDesign(suggestion: suggestion, colors: colors, generatedImageData: imageData)
        modelContext.insert(favorite)
        isFavorited = true
        showFavoriteSuccess = true
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
                    .foregroundColor(Color.appAccent)
                Text("Shop This Look")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text("via Amazon")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }

            Text("Closest matching polishes for your colors. Availability may vary.")
                .font(.system(size: 11))
                .foregroundColor(Color.textSecondary)

            ForEach(matches, id: \.0.id) { color, products in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .shadow(color: color.swiftUIColor.opacity(0.3), radius: 3, x: 0, y: 1)
                        Text(color.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
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
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.textSecondary)
                                        Text(product.name)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color.textPrimary)
                                    }

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Text("Buy")
                                            .font(.system(size: 11, weight: .semibold))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(Color.appAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.appAccent.opacity(0.08))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                                }
                                .padding(12)
                                .background(Color.appBackground)
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
                .foregroundColor(Color.textSecondary.opacity(0.7))
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

        case .square:
            let r: CGFloat = 3
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addQuadCurve(to: CGPoint(x: r, y: 0),
                              control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: w - r, y: 0))
            path.addQuadCurve(to: CGPoint(x: w, y: r),
                              control: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
        }

        return path
    }
}
