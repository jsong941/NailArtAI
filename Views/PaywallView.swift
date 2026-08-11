import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: PurchaseTier = .pro
    @State private var animateIn = false

    enum PurchaseTier: CaseIterable {
        case starter, value, pro

        var title: String {
            switch self {
            case .starter: return "Starter Pack"
            case .value:   return "Value Pack"
            case .pro:     return "Pro Monthly"
            }
        }

        var generations: String {
            switch self {
            case .starter: return "5 generations"
            case .value:   return "15 generations"
            case .pro:     return "40 generations/mo"
            }
        }

        var fallbackPrice: String {
            switch self {
            case .starter: return "$0.99"
            case .value:   return "$2.99"
            case .pro:     return "$9.99"
            }
        }

        var productID: String {
            switch self {
            case .starter: return SubscriptionManager.starterPackID
            case .value:   return SubscriptionManager.valuePackID
            case .pro:     return SubscriptionManager.proMonthlyID
            }
        }

        var badge: String? {
            switch self {
            case .value:   return "Best Value"
            case .pro:     return "Most Popular"
            case .starter: return nil
            }
        }

        var detail: String {
            switch self {
            case .starter: return "One-time purchase · never expires"
            case .value:   return "One-time purchase · never expires"
            case .pro:     return "Renews monthly · cancel anytime"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(Color.appAccent)
                    }
                    .padding(.top, 40)

                    Text("Get More Designs")
                        .font(.custom("CormorantGaramond-SemiBold", size: 30))
                        .foregroundColor(Color.textPrimary)

                    Text("You've used your free generations.\nChoose a plan to keep creating.")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: animateIn)

                // Tier cards
                VStack(spacing: 10) {
                    ForEach(PurchaseTier.allCases, id: \.title) { tier in
                        TierCard(
                            tier: tier,
                            isSelected: selectedTier == tier,
                            price: subscriptionManager.product(for: tier.productID)?.displayPrice ?? tier.fallbackPrice
                        )
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedTier = tier
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)

                Spacer()

                // CTA
                VStack(spacing: 12) {
                    Button {
                        Task { await subscriptionManager.purchase(productID: selectedTier.productID) }
                    } label: {
                        ZStack {
                            if subscriptionManager.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                let price = subscriptionManager.product(for: selectedTier.productID)?.displayPrice ?? selectedTier.fallbackPrice
                                VStack(spacing: 2) {
                                    Text(selectedTier == .pro ? "Subscribe — \(price)/month" : "Buy \(selectedTier.title) — \(price)")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(selectedTier.detail)
                                        .font(.system(size: 11))
                                        .opacity(0.8)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(subscriptionManager.isPurchasing
                            ? Color.appAccent.opacity(0.6)
                            : Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.appAccent.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .disabled(subscriptionManager.isPurchasing)

                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                    }

                    Text("Subscription auto-renews monthly. Manage or cancel in your Apple ID settings.")
                        .font(.system(size: 10))
                        .foregroundColor(Color.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: URL(string: "https://purrfect-allium-817.notion.site/Nomi-Nail-33c61c6829748062a855e2d6950c91f2")!)
                        Text("·")
                        Link("Terms of Use", destination: URL(string: "https://purrfect-allium-817.notion.site/Nomi-Nail-Terms-of-Use-33e61c68297480c08456c009545df66a")!)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
            }

            // Dismiss button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.divider)
                            .clipShape(Circle())
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onAppear { animateIn = true }
        .onChange(of: subscriptionManager.isSubscribed) { _, isSubscribed in
            if isSubscribed { dismiss() }
        }
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let tier: PaywallView.PurchaseTier
    let isSelected: Bool
    let price: String

    var body: some View {
        HStack(spacing: 14) {
            // Radio button
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.appAccent : Color.divider, lineWidth: 2)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 12, height: 12)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(tier.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    if let badge = tier.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.appAccent)
                            .clipShape(Capsule())
                    }
                }
                Text(tier.generations)
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)
            }

            Spacer()

            Text(price)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? Color.appAccent : Color.textPrimary)
        }
        .padding(16)
        .background(isSelected ? Color.appAccent.opacity(0.06) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.appAccent : Color.divider, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.03), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
