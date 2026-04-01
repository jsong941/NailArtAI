import SwiftUI

struct ColorSelectionView: View {
    let image: UIImage
    @StateObject private var viewModel = ColorSelectionViewModel()
    @State private var navigateToResults = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Photo
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.05), value: animateIn)

                    // Header
                    VStack(spacing: 4) {
                        Text("Choose Your Colors")
                            .font(.custom("CormorantGaramond-Bold", size: 26))
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Text("Select 1 or 2 colors to base your designs on")
                            .font(.custom("CormorantGaramond-Italic", size: 15))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.12), value: animateIn)

                    // Loading state
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(Color(hex: "C9A84C"))
                                .scaleEffect(1.2)
                            Text("Extracting colors...")
                                .font(.custom("CormorantGaramond-Italic", size: 15))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.custom("CormorantGaramond-Italic", size: 15))
                            .foregroundColor(.red.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else {
                        // Color cards
                        VStack(spacing: 16) {
                            ForEach(viewModel.visibleColors) { color in
                                ColorCard(
                                    color: color,
                                    isSelected: viewModel.selectedIDs.contains(color.id),
                                    selectionIndex: selectionIndex(for: color)
                                ) {
                                    viewModel.toggle(color)
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // Add more button
                            if viewModel.canShowMore {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        viewModel.showNextColor()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 15, weight: .medium))
                                        Text("Show next color")
                                            .font(.custom("CormorantGaramond-SemiBold", size: 16))
                                    }
                                    .foregroundColor(Color(hex: "C9A84C"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color(hex: "C9A84C").opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "C9A84C").opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.horizontal, 24)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.visibleCount)
                    }

                    Spacer().frame(height: 100)
                }
            }

            // Generate button pinned to bottom
            VStack {
                Spacer()
                NavigationLink(destination: ResultsView(selectedColors: viewModel.selectedColors), isActive: $navigateToResults) {
                    EmptyView()
                }
                Button {
                    navigateToResults = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                        Text(viewModel.selectedIDs.isEmpty ? "Select a color to continue" : "Generate Designs")
                            .font(.custom("CormorantGaramond-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        viewModel.canGenerateDesigns
                            ? LinearGradient(colors: [Color(hex: "C9A84C"), Color(hex: "B8860B")], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(hex: "C9A84C").opacity(0.4), Color(hex: "B8860B").opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(hex: "C9A84C").opacity(viewModel.canGenerateDesigns ? 0.3 : 0), radius: 10, x: 0, y: 4)
                }
                .disabled(!viewModel.canGenerateDesigns)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FAFAF8").opacity(0), Color(hex: "FAFAF8")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 120)
                    .ignoresSafeArea()
                )
            }
        }
        .navigationTitle("Color Palette")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateIn = true
            viewModel.extractColors(from: image)
        }
    }

    private func selectionIndex(for color: NailColor) -> Int? {
        let selected = viewModel.selectedColors
        return selected.firstIndex(where: { $0.id == color.id }).map { $0 + 1 }
    }
}

// MARK: - Color Card
struct ColorCard: View {
    let color: NailColor
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    // Main color swatch
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.swiftUIColor)
                        .frame(width: 52, height: 52)
                        .shadow(color: color.swiftUIColor.opacity(0.4), radius: 6, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(color.name)
                            .font(.custom("CormorantGaramond-SemiBold", size: 17))
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Text("#\(color.hex.uppercased())")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color(hex: "C9A84C") : Color(hex: "E5E5EA"))
                            .frame(width: 28, height: 28)
                        if isSelected, let index = selectionIndex {
                            Text("\(index)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Color series: lighter → base → deeper
                HStack(spacing: 8) {
                    ForEach(Array(zip(["Lighter", "Base", "Deeper"], color.series)), id: \.0) { label, seriesColor in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(seriesColor)
                                .frame(height: 32)
                                .shadow(color: seriesColor.opacity(0.3), radius: 3, x: 0, y: 1)
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? Color(hex: "C9A84C") : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: isSelected ? Color(hex: "C9A84C").opacity(0.15) : Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
