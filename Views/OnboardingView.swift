import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.fill",
            title: "Any Photo,\nAnywhere",
            description: "Snap a photo or pick one from your library — a sunset, outfit, painting, or anything that catches your eye."
        ),
        OnboardingPage(
            icon: "bag.fill",
            title: "Shop Your\nExact Colors",
            description: "Doing your nails yourself? AI matches your photo's colors to real nail polishes on Amazon so you can buy exactly what you need."
        ),
        OnboardingPage(
            icon: "wand.and.sparkles",
            title: "Generate AI\nNail Art",
            description: "Seeing a professional? Get AI-generated nail art inspired by your photo to show your nail tech exactly what you're envisioning."
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.35)) { hasSeenOnboarding = true }
                        } label: {
                            Text("Skip")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textSecondary)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                        }
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }

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
                            .fill(i == currentPage ? Color.appAccent : Color.divider)
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

// MARK: - Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Single Onboarding Page

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.06))
                    .frame(width: 170, height: 170)
                Circle()
                    .fill(Color.appAccent.opacity(0.1))
                    .frame(width: 130, height: 130)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(Color.appAccent)
            }
            .scaleEffect(animateIn ? 1 : 0.75)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.05), value: animateIn)
            .padding(.bottom, 44)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.custom("CormorantGaramond-Bold", size: 40))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(Color.textSecondary)
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
