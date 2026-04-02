import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            icon: "camera.fill",
            title: "Capture Any Color",
            description: "Snap a photo or upload from your library — a sunset, a painting, a fabric swatch. Anything that inspires you."
        ),
        (
            icon: "sparkles",
            title: "AI Reads Your Colors",
            description: "Gemini AI extracts the dominant colors and builds a beautiful shade palette just from your image."
        ),
        (
            icon: "paintpalette.fill",
            title: "Designs Made for You",
            description: "Pick your favorite shades and get four unique nail art designs tailored to your exact palette."
        )
    ]

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8").ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color(hex: "C9A84C") : Color(hex: "E5E5EA"))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // CTA button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage += 1 }
                    } else {
                        withAnimation(.easeInOut(duration: 0.35)) { hasSeenOnboarding = true }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.custom("CormorantGaramond-SemiBold", size: 18))
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
                        .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

// MARK: - Single Onboarding Page
struct OnboardingPageView: View {
    let page: (icon: String, title: String, description: String)
    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "C9A84C").opacity(0.1))
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(Color(hex: "C9A84C").opacity(0.06))
                    .frame(width: 170, height: 170)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(Color(hex: "C9A84C"))
            }
            .scaleEffect(animateIn ? 1 : 0.75)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.05), value: animateIn)
            .padding(.bottom, 44)

            // Text
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.custom("CormorantGaramond-Bold", size: 32))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.custom("CormorantGaramond-Italic", size: 17))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 18)
            .animation(.easeOut(duration: 0.45).delay(0.15), value: animateIn)

            Spacer()
            Spacer()
        }
        .onAppear { animateIn = true }
        .onDisappear { animateIn = false }
    }
}

#Preview {
    OnboardingView()
}
