import SwiftUI

struct ResultsView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResultsViewModel()
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Uploaded image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(.easeOut(duration: 0.45).delay(0.1), value: animateIn)

                    // Error State
                    if let error = viewModel.errorMessage {
                        ErrorCard(message: error)
                            .padding(.horizontal, 24)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.45).delay(0.22), value: animateIn)
                    }

                    // Color Palette Section
                    if viewModel.errorMessage == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Color Palette", icon: "paintpalette.fill")

                            if viewModel.isLoading {
                                LoadingCard()
                            } else {
                                ColorPaletteCard(colors: viewModel.suggestedColors)
                            }
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(.easeOut(duration: 0.45).delay(0.22), value: animateIn)

                        // Design Suggestions Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Design Ideas", icon: "sparkles")

                            if viewModel.isLoading {
                                LoadingCard()
                            } else {
                                ForEach(viewModel.designSuggestions) { suggestion in
                                    NavigationLink(destination: DesignDetailView(suggestion: suggestion, colors: viewModel.suggestedColors)) {
                                        DesignSuggestionCard(suggestion: suggestion)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(.easeOut(duration: 0.45).delay(0.34), value: animateIn)
                    }

                    // Save button
                    Button {
                        viewModel.saveToLibrary(image: image)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.down.to.line.circle.fill")
                                .font(.system(size: 17))
                            Text("Save Design")
                                .font(.custom("CormorantGaramond-SemiBold", size: 18))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "C9A84C"), Color(hex: "B8860B")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: 12, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.46), value: animateIn)

                    Spacer().frame(height: 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Your Designs")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved!", isPresented: $viewModel.showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your design has been saved to your photo library.")
        }
        .alert("Permission Needed", isPresented: $viewModel.showPermissionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please allow photo library access in Settings to save designs.")
        }
        .onAppear {
            animateIn = true
            if !viewModel.hasAnalyzed {
                viewModel.analyzeImage(image)
            }
        }
    }
}

// MARK: - Subviews

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "C9A84C"))
            Text(title)
                .font(.custom("CormorantGaramond-Bold", size: 20))
                .foregroundColor(Color(hex: "1C1C1E"))
        }
    }
}

struct ColorPaletteCard: View {
    let colors: [NailColor]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(colors) { color in
                VStack(spacing: 7) {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 42, height: 42)
                        .shadow(color: color.swiftUIColor.opacity(0.35), radius: 6, x: 0, y: 3)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    Text(color.name)
                        .font(.custom("CormorantGaramond-Regular", size: 11))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

struct DesignSuggestionCard: View {
    let suggestion: DesignSuggestion

    var body: some View {
        HStack(spacing: 14) {
            Text(suggestion.emoji)
                .font(.system(size: 28))
                .frame(width: 50, height: 50)
                .background(Color(hex: "F5F0E8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.title)
                    .font(.custom("CormorantGaramond-SemiBold", size: 17))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Text(suggestion.description)
                    .font(.custom("CormorantGaramond-Italic", size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "C9A84C"))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ErrorCard: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "C9A84C"))
            VStack(alignment: .leading, spacing: 3) {
                Text("Something went wrong")
                    .font(.custom("CormorantGaramond-SemiBold", size: 16))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Text(message)
                    .font(.custom("CormorantGaramond-Italic", size: 13))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

struct LoadingCard: View {
    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .frame(height: 80)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color(hex: "C9A84C"))
                    Text("Analyzing your photo...")
                        .font(.custom("CormorantGaramond-Italic", size: 15))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            )
            .opacity(shimmer ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.9).repeatForever(), value: shimmer)
            .onAppear { shimmer = true }
    }
}

