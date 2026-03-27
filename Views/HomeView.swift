import SwiftUI

struct HomeView: View {
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var navigateToResults = false
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Clean white background
                Color(hex: "FAFAF8")
                    .ignoresSafeArea()

                // Subtle warm top glow
                VStack {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "C9A84C").opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 220
                            )
                        )
                        .frame(width: 420, height: 260)
                        .offset(y: -40)
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    // Top bar
                    HStack {
                        Spacer()
                        Text("✦")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "C9A84C"))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F5F0E8"))
                                .frame(width: 76, height: 76)
                                .shadow(color: Color(hex: "C9A84C").opacity(0.2), radius: 16, x: 0, y: 6)

                            Text("💅")
                                .font(.system(size: 36))
                        }
                        .scaleEffect(animateIn ? 1 : 0.7)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.1), value: animateIn)

                        Text("NailArtAI")
                            .font(.custom("CormorantGaramond-Bold", size: 36))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.2), value: animateIn)

                        Text("Your personal nail art designer")
                            .font(.custom("CormorantGaramond-Italic", size: 16))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 12)
                            .animation(.easeOut(duration: 0.45).delay(0.28), value: animateIn)
                    }
                    .padding(.top, 28)

                    Spacer()

                    // Hero card
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 8)

                            VStack(spacing: 16) {
                                // Decorative color dots
                                HStack(spacing: 10) {
                                    ForEach(["E8C5A0", "D4A853", "C9A84C", "B8956A", "F0E0C0"], id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 28, height: 28)
                                            .shadow(color: Color(hex: hex).opacity(0.4), radius: 4, x: 0, y: 2)
                                    }
                                }

                                VStack(spacing: 6) {
                                    Text("Snap. Inspire. Design.")
                                        .font(.custom("CormorantGaramond-SemiBold", size: 20))
                                        .foregroundColor(Color(hex: "1C1C1E"))

                                    Text("Point your camera at any color, artwork,\nor object to get curated nail designs.")
                                        .font(.custom("CormorantGaramond-Italic", size: 15))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                }
                            }
                            .padding(28)
                        }
                        .padding(.horizontal, 24)

                        // How it works - 3 steps
                        HStack(spacing: 0) {
                            ForEach(steps, id: \.title) { step in
                                VStack(spacing: 6) {
                                    Text(step.icon)
                                        .font(.system(size: 22))
                                    Text(step.title)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                }
                                .frame(maxWidth: .infinity)

                                if step.title != steps.last?.title {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color(hex: "C9A84C").opacity(0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.35), value: animateIn)

                    Spacer()

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Take a Photo")
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
                            .shadow(color: Color(hex: "C9A84C").opacity(0.35), radius: 12, x: 0, y: 5)
                        }

                        Button {
                            showImagePicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 15, weight: .medium))
                                Text("Upload from Library")
                                    .font(.custom("CormorantGaramond-SemiBold", size: 18))
                            }
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "E5E5EA"), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 24)
                    .animation(.easeOut(duration: 0.5).delay(0.45), value: animateIn)

                    Spacer().frame(height: 44)
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                if let image = selectedImage {
                    ResultsView(image: image)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedImage, sourceType: .photoLibrary) {
                    navigateToResults = true
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(image: $selectedImage, sourceType: .camera) {
                    navigateToResults = true
                }
            }
            .onAppear {
                animateIn = true
            }
        }
    }

    let steps: [(icon: String, title: String)] = [
        (icon: "📸", title: "Capture"),
        (icon: "✨", title: "Analyze"),
        (icon: "💅", title: "Design")
    ]
}

#Preview {
    HomeView()
}

