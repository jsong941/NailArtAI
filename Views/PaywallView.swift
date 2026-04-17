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
            case .value:   return "20 generations"
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
            Color(hex: "FCFAF8").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "C9A84C").opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(Color(hex: "C9A84C"))
                    }
                    .padding(.top, 40)

                    Text("Get More Designs")
                        .font(.custom("CormorantGaramond-SemiBold", size: 30))
                        .foregroundColor(Color(hex: "2C2925"))

                    Text("You've used your free generations.\nChoose a plan to keep creating.")
                        .font(.custom("CormorantGaramond-Italic", size: 16))
                        .foregroundColor(Color(hex: "8E8A83"))
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
                                        .font(.custom("CormorantGaramond-SemiBold", size: 18))
                                    Text(selectedTier.detail)
                                        .font(.custom("CormorantGaramond-Italic", size: 12))
                                        .opacity(0.8)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(subscriptionManager.isPurchasing
                            ? Color(hex: "C9A84C").opacity(0.6)
                            : Color(hex: "C9A84C"))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .disabled(subscriptionManager.isPurchasing)

                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.custom("CormorantGaramond-Regular", size: 14))
                            .foregroundColor(Color(hex: "8E8A83"))
                    }

                    Text("Subscription auto-renews monthly. Manage or cancel in your Apple ID settings.")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "8E8A83").opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: URL(string: "https://purrfect-allium-817.notion.site/Nomi-Nail-33c61c6829748062a855e2d6950c91f2")!)
                        Text("·")
                        Link("Terms of Use", destination: URL(string: "https://purrfect-allium-817.notion.site/Nomi-Nail-Terms-of-Use-33e61c68297480c08456c009545df66a")!)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8E8A83"))
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
                            .foregroundColor(Color(hex: "8E8A83"))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "E8E4DF"))
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
                    .stroke(isSelected ? Color(hex: "C9A84C") : Color(hex: "D1D1D6"), lineWidth: 2)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle()
                        .fill(Color(hex: "C9A84C"))
                        .frame(width: 12, height: 12)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(tier.title)
                        .font(.custom("CormorantGaramond-SemiBold", size: 16))
                        .foregroundColor(Color(hex: "2C2925"))
                    if let badge = tier.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(hex: "C9A84C"))
                            .clipShape(Capsule())
                    }
                }
                Text(tier.generations)
                    .font(.custom("CormorantGaramond-Italic", size: 13))
                    .foregroundColor(Color(hex: "8E8A83"))
            }

            Spacer()

            Text(price)
                .font(.custom("CormorantGaramond-SemiBold", size: 18))
                .foregroundColor(isSelected ? Color(hex: "C9A84C") : Color(hex: "2C2925"))
        }
        .padding(16)
        .background(isSelected ? Color(hex: "C9A84C").opacity(0.06) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color(hex: "C9A84C") : Color(hex: "E8E4DF"), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.03), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
