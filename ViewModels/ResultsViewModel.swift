import SwiftUI
import Combine
import Photos

@MainActor
class ResultsViewModel: ObservableObject {
    @Published var suggestedColors: [NailColor] = []
    @Published var designSuggestions: [DesignSuggestion] = []
    @Published var isLoading = false
    @Published var hasAnalyzed = false
    @Published var errorMessage: String? = nil
    @Published var showSaveSuccess = false
    @Published var showPermissionError = false

    private let geminiService = GeminiService()

    // MARK: - Analyze Image
    func analyzeImage(_ image: UIImage) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await geminiService.analyzeImage(image)
                suggestedColors = result.colors
                designSuggestions = result.suggestions
                hasAnalyzed = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Save to Photo Library
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
