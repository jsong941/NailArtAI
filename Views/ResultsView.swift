import SwiftUI
import SwiftData

struct ResultsView: View {
    let selectedColors: [NailColor]
    var selectedShape: NailShapeType = .rounded
    var sourceImage: UIImage? = nil
    @StateObject private var viewModel = ResultsViewModel()
    @State private var animateIn = false
    @State private var hasSavedToHistory = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Selected color palette summary
                    HStack(spacing: 12) {
                        ForEach(selectedColors) { color in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: color.swiftUIColor.opacity(0.35), radius: 6, x: 0, y: 3)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Text(color.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.05), value: animateIn)

                    // Error
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            ErrorCard(message: error)
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.retryGenerateDesigns(for: selectedColors)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Try Again")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Color.appAccent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.appAccent.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appAccent.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    }

                    // Design Suggestions
                    if viewModel.errorMessage == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Design Ideas", icon: "sparkles")

                            if viewModel.isLoading {
                                LoadingCard()
                                LoadingCard()
                                LoadingCard()
                            } else {
                                ForEach(viewModel.designSuggestions) { suggestion in
                                    NavigationLink(destination: DesignDetailView(suggestion: suggestion, colors: selectedColors, selectedShape: selectedShape, sourceImage: sourceImage)) {
                                        DesignSuggestionCard(suggestion: suggestion)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    })
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(.easeOut(duration: 0.45).delay(0.15), value: animateIn)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("Design Ideas")
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
            viewModel.generateDesigns(for: selectedColors)
        }
        .onChange(of: viewModel.hasLoaded) { _, loaded in
            guard loaded, !hasSavedToHistory else { return }
            let session = HistorySession(colors: selectedColors, designs: viewModel.designSuggestions)
            modelContext.insert(session)
            hasSavedToHistory = true
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
                .foregroundColor(Color.appAccent)
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.textPrimary)
        }
    }
}

struct DesignSuggestionCard: View {
    let suggestion: DesignSuggestion

    var body: some View {
        HStack(spacing: 14) {
            Text(suggestion.emoji)
                .font(.system(size: 28))
                .frame(width: 50, height: 50)
                .background(Color.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(suggestion.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appAccent)
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
                .foregroundColor(Color.appAccent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Something went wrong")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
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
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentSoft)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 8) {
                Capsule()
                    .fill(Color.accentSoft)
                    .frame(width: 150, height: 12)
                Capsule()
                    .fill(Color.accentSoft.opacity(0.55))
                    .frame(width: 92, height: 10)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .shimmer()
    }
}

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.appAccent.opacity(0.10), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * phase)
                }
                .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}
