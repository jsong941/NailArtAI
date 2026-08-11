import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \FavoriteDesign.savedAt, order: .reverse) private var favorites: [FavoriteDesign]
    @Environment(\.modelContext) private var modelContext
    @State private var renaming: FavoriteDesign? = nil
    @State private var renameText = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

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
                        .contextMenu {
                            Button {
                                renameText = favorite.title
                                renaming = favorite
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(favorite)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
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
        .alert("Rename", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let favorite = renaming, !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                    favorite.title = renameText.trimmingCharacters(in: .whitespaces)
                }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
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
                .background(Color.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)

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
            Color.appBackground.ignoresSafeArea()

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
                                    .foregroundColor(Color.appAccent)
                                Text("Save to Photos")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
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
                                .background(Color.textPrimary)
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
                .foregroundColor(Color.appAccent.opacity(0.5))

            Text("No Favorites Yet")
                .font(.custom("CormorantGaramond-Bold", size: 24))
                .foregroundColor(Color.textPrimary)

            Text("Tap the heart on any design\nto save it here.")
                .font(.system(size: 13))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}
