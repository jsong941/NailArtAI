import SwiftUI
import SwiftData

struct ColorSelectionView: View {
    let image: UIImage
    @StateObject private var viewModel = ColorSelectionViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var hasSavedToHistory = false
    @State private var showIntentSheet = false
    @State private var navigateToShop = false
    @State private var navigateToGenerate = false
    @State private var animateIn = false
    @State private var selectedShape: NailShapeType = .rounded

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // Photo
                    Color.clear
                        .frame(height: 220)
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.05), value: animateIn)

                    // Color palette
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 7) {
                            Image(systemName: "eyedropper")
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(Color.appAccent)
                            Text("Color Palette")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                        }

                        if viewModel.isLoading {
                            HStack(spacing: 12) {
                                ProgressView().tint(Color.appAccent)
                                Text("Extracting colors...")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                        } else if let error = viewModel.errorMessage {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(error)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textSecondary)
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    viewModel.extractColors(from: image)
                                } label: {
                                    Text("Try Again")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color.appAccent)
                                }
                            }
                        } else {
                            HStack(alignment: .top, spacing: 14) {
                                Spacer()
                                ForEach(viewModel.allColors) { color in
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(color.swiftUIColor)
                                            .frame(width: 54, height: 54)
                                            .shadow(color: color.swiftUIColor.opacity(0.3), radius: 5, x: 0, y: 2)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        Text(color.name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color.textSecondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .minimumScaleFactor(0.8)
                                            .frame(width: 64)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.12), value: animateIn)

                    Spacer().frame(height: 180)
                }
            }

            // Nail shape + Generate pinned to bottom
            VStack {
                Spacer()

                VStack(spacing: 14) {
                    // Nail shape picker
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "oval.portrait")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(Color.appAccent)
                            Text("Nail Shape")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                        }
                        HStack(spacing: 10) {
                            ForEach(NailShapeType.allCases, id: \.self) { shape in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedShape = shape
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        NailShape(shapeType: shape)
                                            .fill(selectedShape == shape ? Color.appAccent : Color.divider)
                                            .frame(width: 26, height: 40)
                                        Text(shape.displayName)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(selectedShape == shape ? Color.appAccent : Color.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedShape == shape ? Color.appAccent.opacity(0.08) : Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedShape == shape ? Color.appAccent.opacity(0.5) : Color.divider, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Generate button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showIntentSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "wand.and.sparkles")
                                .font(.system(size: 15, weight: .light))
                            Text(viewModel.isLoading ? "Analyzing Photo..." : "Generate Design")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(viewModel.canGenerate ? Color.textPrimary : Color.textPrimary.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .disabled(!viewModel.canGenerate)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
                .background(
                    LinearGradient(
                        colors: [Color.appBackground.opacity(0), Color.appBackground],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 200).ignoresSafeArea()
                )
            }
        }
        .navigationDestination(isPresented: $navigateToShop) {
            DesignDetailView(colors: viewModel.allColors, selectedShape: selectedShape, sourceImage: image)
        }
        .navigationDestination(isPresented: $navigateToGenerate) {
            GenerateDesignView(colors: viewModel.allColors, selectedShape: selectedShape, sourceImage: image)
        }
        .sheet(isPresented: $showIntentSheet) {
            NailIntentSheet(
                onSelf: {
                    showIntentSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigateToShop = true
                    }
                },
                onPro: {
                    showIntentSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigateToGenerate = true
                    }
                }
            )
            .presentationDetents([.height(320)])
            .presentationCornerRadius(28)
        }
        .navigationTitle("Your Photo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateIn = true
            viewModel.extractColors(from: image)
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            guard !isLoading, !viewModel.allColors.isEmpty, !hasSavedToHistory else { return }
            hasSavedToHistory = true
            modelContext.insert(HistorySession(colors: viewModel.allColors, designs: []))
        }
    }
}

// MARK: - Intent Sheet

struct NailIntentSheet: View {
    let onSelf: () -> Void
    let onPro: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Handle
            Capsule()
                .fill(Color.divider)
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Text("How are you getting your nails done?")
                .font(.custom("CormorantGaramond-SemiBold", size: 22))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 4)

            VStack(spacing: 12) {
                // Myself
                Button(action: onSelf) {
                    HStack(spacing: 16) {
                        Text("💅")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Doing it myself")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            Text("Shop matching polishes on Amazon")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                    .padding(16)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Professional
                Button(action: onPro) {
                    HStack(spacing: 16) {
                        Text("✨")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Going to a professional")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            Text("Generate AI nail art to show your tech")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                    .padding(16)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.appBackground)
    }
}
