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
                Color(hex: "FAFAF8")
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()

                    // Header
                    VStack(spacing: 8) {
                        Text("NailArtAI")
                            .font(.custom("CormorantGaramond-Bold", size: 42))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 16)
                            .animation(.easeOut(duration: 0.45).delay(0.1), value: animateIn)

                        Text("Your personal nail art designer")
                            .font(.custom("CormorantGaramond-Italic", size: 16))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(.easeOut(duration: 0.45).delay(0.18), value: animateIn)
                    }
                    .padding(.bottom, 48)

                    // Color dots
                    HStack(spacing: 10) {
                        ForEach(["E8C5A0", "D4A853", "C9A84C", "B8956A", "F0E0C0"], id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .shadow(color: Color(hex: hex).opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.25), value: animateIn)
                    .padding(.bottom, 32)

                    // Tagline
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
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)
                    .animation(.easeOut(duration: 0.45).delay(0.3), value: animateIn)

                    // Step indicators
                    HStack(spacing: 0) {
                        ForEach(steps, id: \.title) { step in
                            VStack(spacing: 6) {
                                Image(systemName: step.icon)
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(Color(hex: "C9A84C"))
                                Text(step.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "8E8E93"))
                            }
                            .frame(maxWidth: .infinity)

                            if step.title != steps.last?.title {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(hex: "C9A84C").opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 36)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.35), value: animateIn)

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
                            .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: 10, x: 0, y: 4)
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
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateIn)

                    Spacer().frame(height: 48)
                }
            }
            .navigationDestination(isPresented: $navigateToResults) {
                if let image = selectedImage {
                    ColorSelectionView(image: image)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 18) {
                        NavigationLink(destination: FavoritesView()) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "C9A84C"))
                        }
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "C9A84C"))
                        }
                    }
                }
            }
            .onAppear {
                animateIn = true
            }
        }
    }

    let steps: [(icon: String, title: String)] = [
        (icon: "camera", title: "Capture"),
        (icon: "sparkles", title: "Analyze"),
        (icon: "paintpalette", title: "Design")
    ]
}

#Preview {
    HomeView()
}
