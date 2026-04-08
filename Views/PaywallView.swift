import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false

    private var proProduct: Product? {
        subscriptionManager.products.first
    }

    private var priceString: String {
        proProduct?.displayPrice ?? "$4.99"
    }

    var body: some View {
        ZStack {
            Color(hex: "FCFAF8").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "C9A84C").opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Color(hex: "C9A84C"))
                    }
                    .padding(.top, 40)

                    Text("Vernis Pro")
                        .font(.custom("CormorantGaramond-SemiBold", size: 32))
                        .foregroundColor(Color(hex: "2C2925"))

                    Text("20 AI nail art designs every month")
                        .font(.custom("CormorantGaramond-Italic", size: 17))
                        .foregroundColor(Color(hex: "8E8A83"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: animateIn)

                // Usage indicator
                usageCard
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)

                // Benefits
                benefitsCard
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.18), value: animateIn)

                Spacer()

                // CTA
                VStack(spacing: 12) {
                    Button {
                        Task { await subscriptionManager.purchase() }
                    } label: {
                        ZStack {
                            if subscriptionManager.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                VStack(spacing: 2) {
                                    Text("Start Pro — \(priceString)/month")
                                        .font(.custom("CormorantGaramond-SemiBold", size: 18))
                                    Text("Cancel anytime in App Store settings")
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.26), value: animateIn)
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

    // MARK: - Usage Card

    @ViewBuilder
    private var usageCard: some View {
        let used = SubscriptionManager.freeLimit - subscriptionManager.generationsRemaining
        let total = SubscriptionManager.freeLimit

        VStack(spacing: 10) {
            HStack {
                Text("Free generations used")
                    .font(.custom("CormorantGaramond-SemiBold", size: 15))
                    .foregroundColor(Color(hex: "2C2925"))
                Spacer()
                Text("\(used) of \(total)")
                    .font(.custom("CormorantGaramond-SemiBold", size: 15))
                    .foregroundColor(Color(hex: "C9A84C"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "E8E4DF"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "C9A84C"))
                        .frame(width: total > 0 ? geo.size.width * CGFloat(used) / CGFloat(total) : 0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Benefits Card

    @ViewBuilder
    private var benefitsCard: some View {
        VStack(spacing: 0) {
            benefitRow(emoji: "✨", title: "20 AI designs/month", subtitle: "Resets every month, no rollover pressure")
            Divider().opacity(0.4).padding(.horizontal, 16)
            benefitRow(emoji: "🛍️", title: "Shop This Look — always free", subtitle: "Amazon affiliate links, no subscription needed")
            Divider().opacity(0.4).padding(.horizontal, 16)
            benefitRow(emoji: "⭐", title: "Priority access to new features", subtitle: "Style presets, inspo gallery, and more")
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func benefitRow(emoji: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.custom("CormorantGaramond-SemiBold", size: 16))
                .foregroundColor(Color(hex: "2C2925"))
            Text(subtitle)
                .font(.custom("CormorantGaramond-Italic", size: 13))
                .foregroundColor(Color(hex: "8E8A83"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
