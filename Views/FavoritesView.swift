import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \FavoriteDesign.savedAt, order: .reverse) private var favorites: [FavoriteDesign]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color(hex: "FAFAF8").ignoresSafeArea()

            if favorites.isEmpty {
                EmptyFavoritesView()
            } else {
                List {
                    ForEach(favorites) { favorite in
                        Group {
                            if favorite.generatedImageData != nil {
                                NavigationLink(destination: GeneratedFavoriteDetailView(favorite: favorite)) {
                                    FavoriteDesignRow(favorite: favorite)
                                }
                            } else {
                                NavigationLink(destination: DesignDetailView(
                                    suggestion: favorite.asDesignSuggestion,
                                    colors: favorite.colors
                                )) {
                                    FavoriteDesignRow(favorite: favorite)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(favorites[index])
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Favorite Row

struct FavoriteDesignRow: View {
    let favorite: FavoriteDesign

    var body: some View {
        HStack(spacing: 14) {
            Text(favorite.emoji)
                .font(.system(size: 28))
                .frame(width: 50, height: 50)
                .background(Color(hex: "F5F0E8"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.title)
                    .font(.custom("CormorantGaramond-SemiBold", size: 17))
                    .foregroundColor(Color(hex: "1C1C1E"))

                HStack(spacing: -4) {
                    ForEach(Array(favorite.colors.prefix(3).enumerated()), id: \.offset) { index, color in
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .zIndex(Double(3 - index))
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Generated Favorite Detail

struct GeneratedFavoriteDetailView: View {
    let favorite: FavoriteDesign
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color(hex: "FCFAF8").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let image = favorite.generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }

                    HStack(spacing: 10) {
                        Button {
                            guard let image = favorite.generatedImage else { return }
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundColor(Color(hex: "C9A84C"))
                                Text("Save to Photos")
                                    .font(.custom("CormorantGaramond-SemiBold", size: 17))
                                    .foregroundColor(Color(hex: "2C2925"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        }

                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 58, height: 58)
                                .background(Color(hex: "2C2925"))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle(favorite.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let image = favorite.generatedImage {
                ShareSheet(items: [image])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Empty State

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Color(hex: "C9A84C").opacity(0.5))

            Text("No Favorites Yet")
                .font(.custom("CormorantGaramond-Bold", size: 24))
                .foregroundColor(Color(hex: "1C1C1E"))

            Text("Tap the heart on any design\nto save it here.")
                .font(.custom("CormorantGaramond-Italic", size: 16))
                .foregroundColor(Color(hex: "8E8E93"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}
