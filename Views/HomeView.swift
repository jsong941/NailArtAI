import SwiftUI

struct HomeView: View {
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var rawImage: UIImage?
    @State private var navigateToCrop = false
    @State private var showHelp = false
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()

                    // Hero content
                    VStack(spacing: 20) {
                        // Sparkle icon
                        ZStack {
                            Circle()
                                .fill(Color.accentSoft)
                                .frame(width: 64, height: 64)
                            Image(systemName: "sparkle")
                                .font(.system(size: 26, weight: .light))
                                .foregroundColor(Color.appAccent)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.85)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateIn)

                        // Headline
                        Text("Discover your\nnext style.")
                            .font(.custom("CormorantGaramond-Medium", size: 38))
                            .foregroundColor(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 12)
                            .animation(.easeOut(duration: 0.45).delay(0.18), value: animateIn)

                        // Subtext
                        Text("Point your camera at any color, artwork,\nor object to get curated nail designs.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 8)
                            .animation(.easeOut(duration: 0.45).delay(0.24), value: animateIn)
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 10) {
                        Text("Begin Analysis")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(2)
                            .foregroundColor(Color.textSecondary)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.32), value: animateIn)

                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera")
                                    .font(.system(size: 17, weight: .light))
                                Text("Use Camera")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.appAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: Color.appAccent.opacity(0.28), radius: 14, x: 0, y: 6)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 18)
                        .animation(.easeOut(duration: 0.45).delay(0.36), value: animateIn)

                        Button {
                            showImagePicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 17, weight: .light))
                                    .foregroundColor(Color.textSecondary)
                                Text("Choose Photo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 18)
                        .animation(.easeOut(duration: 0.45).delay(0.42), value: animateIn)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 52)
                }
            }
            .navigationDestination(isPresented: $navigateToCrop) {
                if let raw = rawImage {
                    CropImageView(image: raw)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $rawImage, sourceType: .photoLibrary) {
                    navigateToCrop = true
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(image: $rawImage, sourceType: .camera) {
                    navigateToCrop = true
                }
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nomi Nail")
                        .font(.custom("CormorantGaramond-SemiBold", size: 20))
                        .foregroundColor(Color.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: FavoritesView()) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(Color.textPrimary)
                        }
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(Color.textPrimary)
                        }
                    }
                }
            }
            .onAppear {
                animateIn = true
            }
        }
    }
}

#Preview {
    HomeView()
}
