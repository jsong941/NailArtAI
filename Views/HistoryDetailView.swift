import SwiftUI
import SwiftData

struct HistoryDetailView: View {
    let session: HistorySession
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Color palette card
                    HStack(spacing: 12) {
                        ForEach(session.colors) { color in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: color.swiftUIColor.opacity(0.35), radius: 6, x: 0, y: 3)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
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
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.05), value: animateIn)

                    // Shop This Look
                    VStack(alignment: .leading, spacing: 12) {
                        ShopThisLookCard(colors: session.colors)
                            .padding(.horizontal, 24)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(0.15), value: animateIn)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle(session.createdAt.formatted(.dateTime.month(.wide).day().year()))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animateIn = true }
    }
}
