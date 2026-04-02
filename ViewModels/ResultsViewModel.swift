import SwiftUI
import Combine
import Photos

@MainActor
class ResultsViewModel: ObservableObject {
    @Published var designSuggestions: [DesignSuggestion] = []
    @Published var isLoading = false
    @Published var hasLoaded = false
    @Published var errorMessage: String? = nil
    @Published var showSaveSuccess = false
    @Published var showPermissionError = false

    private let geminiService = GeminiService()

    func retryGenerateDesigns(for colors: [NailColor]) {
        hasLoaded = false
        errorMessage = nil
        generateDesigns(for: colors)
    }

    func generateDesigns(for colors: [NailColor]) {
        guard !hasLoaded else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                designSuggestions = try await geminiService.generateDesigns(for: colors)
                hasLoaded = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func saveToLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    self?.showSaveSuccess = true
                default:
                    self?.showPermissionError = true
                }
            }
        }
    }
}
