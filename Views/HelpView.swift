import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [HelpStep] = [
        HelpStep(
            number: 1,
            icon: "camera",
            title: "Upload a Photo",
            detail: "Tap \"Use Camera\" to take a photo, or \"Choose Photo\" to pick one from your library. Use anything that inspires you — an outfit, a piece of art, nature, or a color you love."
        ),
        HelpStep(
            number: 2,
            icon: "eyedropper",
            title: "Review Your Color Palette",
            detail: "AI automatically extracts the dominant colors from your photo and displays them as a palette. Then pick the nail shape that suits you — Round, Almond, Stiletto, or Flare."
        ),
        HelpStep(
            number: 3,
            icon: "person.fill.questionmark",
            title: "Choose Your Path",
            detail: "Tap \"Generate Design\" and choose how you're getting your nails done:\n• Doing it myself → See matching polishes to buy\n• Going to a professional → Generate AI nail art to show your tech"
        ),
        HelpStep(
            number: 4,
            icon: "bag",
            title: "Shop This Look",
            detail: "For the DIY path, we match your extracted colors to real nail polishes available on Amazon. Tap \"Buy\" on any polish to go directly to the product page."
        ),
        HelpStep(
            number: 5,
            icon: "wand.and.sparkles",
            title: "Generate AI Nail Art",
            detail: "For the professional path, tap \"Generate\" to create a photo-realistic AI nail art design inspired by your photo. You can also add colors from your palette to emphasize and choose a design add-on."
        ),
        HelpStep(
            number: 6,
            icon: "sparkles",
            title: "Design Add-Ons",
            detail: "Customize your AI design with add-ons:\n• French Tips — classic white tips\n• Solid Color — clean, single-color look\n• Gem Stone — crystal and jewel accents\n• Chrome Powder — mirror-finish metallic"
        ),
        HelpStep(
            number: 7,
            icon: "square.and.arrow.down",
            title: "Save or Share",
            detail: "Once your AI nail art is generated, use the Save button to add it to your photo library, or the Share button to send it to your nail tech directly."
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FCFAF8").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "C9A84C").opacity(0.1))
                                    .frame(width: 70, height: 70)
                                Image(systemName: "questionmark")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(Color(hex: "C9A84C"))
                            }
                            .padding(.top, 12)

                            Text("How It Works")
                                .font(.custom("CormorantGaramond-Bold", size: 28))
                                .foregroundColor(Color(hex: "2C2925"))

                            Text("Follow these steps to get your perfect nail look.")
                                .font(.custom("CormorantGaramond-Italic", size: 15))
                                .foregroundColor(Color(hex: "8E8A83"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 28)

                        // Steps
                        VStack(spacing: 0) {
                            ForEach(steps.indices, id: \.self) { i in
                                HelpStepRow(step: steps[i], isLast: i == steps.count - 1)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Tips box
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundColor(Color(hex: "C9A84C"))
                                Text("Tips for Best Results")
                                    .font(.custom("CormorantGaramond-Bold", size: 18))
                                    .foregroundColor(Color(hex: "2C2925"))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(text: "Use well-lit, clear photos for more accurate color extraction")
                                TipRow(text: "Colorful images with 3–5 distinct tones work best")
                                TipRow(text: "Regenerate AI nail art multiple times for different variations")
                                TipRow(text: "Polish availability on Amazon can vary — check back if something is sold out")
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        Spacer().frame(height: 48)
                    }
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("CormorantGaramond-SemiBold", size: 16))
                        .foregroundColor(Color(hex: "C9A84C"))
                }
            }
        }
    }
}

// MARK: - Help Step Model

struct HelpStep {
    let number: Int
    let icon: String
    let title: String
    let detail: String
}

// MARK: - Step Row

struct HelpStepRow: View {
    let step: HelpStep
    let isLast: Bool
    @State private var expanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number + connector line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "C9A84C").opacity(0.12))
                        .frame(width: 36, height: 36)
                    Text("\(step.number)")
                        .font(.custom("CormorantGaramond-SemiBold", size: 16))
                        .foregroundColor(Color(hex: "C9A84C"))
                }
                if !isLast {
                    Rectangle()
                        .fill(Color(hex: "E8E4DF"))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: step.icon)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color(hex: "8E8A83"))
                            .frame(width: 18)
                        Text(step.title)
                            .font(.custom("CormorantGaramond-SemiBold", size: 17))
                            .foregroundColor(Color(hex: "2C2925"))
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "C9A84C"))
                    }
                }
                .buttonStyle(.plain)

                if expanded {
                    Text(step.detail)
                        .font(.custom("CormorantGaramond-Italic", size: 15))
                        .foregroundColor(Color(hex: "6B6760"))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                        .padding(.leading, 28)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

// MARK: - Tip Row

struct TipRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(hex: "C9A84C"))
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(.custom("CormorantGaramond-Regular", size: 14))
                .foregroundColor(Color(hex: "6B6760"))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
