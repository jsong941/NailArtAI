import SwiftUI

struct DesignDetailView: View {
    let suggestion: DesignSuggestion
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {

                    // Emoji hero
                    Text(suggestion.emoji)
                        .font(.system(size: 80))
                        .frame(width: 140, height: 140)
                        .background(Color(hex: "F5F0E8"))
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.top, 12)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.85)
                        .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.05), value: animateIn)

                    // Title
                    Text(suggestion.title)
                        .font(.custom("CormorantGaramond-Bold", size: 32))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 12)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)

                    // Gold divider
                    Rectangle()
                        .fill(Color(hex: "C9A84C").opacity(0.4))
                        .frame(width: 48, height: 1.5)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)

                    // Description card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 7) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "C9A84C"))
                            Text("Design Description")
                                .font(.custom("CormorantGaramond-Bold", size: 20))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }

                        Text(suggestion.description)
                            .font(.custom("CormorantGaramond-Regular", size: 18))
                            .foregroundColor(Color(hex: "3C3C3E"))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: animateIn)

                    // Tips card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 7) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "C9A84C"))
                            Text("Pro Tips")
                                .font(.custom("CormorantGaramond-Bold", size: 20))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            TipRow(text: "Apply a base coat to help the colors pop and last longer.")
                            TipRow(text: "Use thin layers and let each coat dry fully before the next.")
                            TipRow(text: "Finish with a glossy top coat to seal and protect your design.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.35), value: animateIn)

                    Spacer().frame(height: 32)
                }
            }
        }
        .navigationTitle(suggestion.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animateIn = true }
    }
}

struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(hex: "C9A84C"))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.custom("CormorantGaramond-Italic", size: 15))
                .foregroundColor(Color(hex: "8E8E93"))
                .lineSpacing(3)
        }
    }
}
