import SwiftUI
import Combine

@MainActor
class ColorSelectionViewModel: ObservableObject {
    @Published var allColors: [NailColor] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let geminiService = GeminiService()

    var canGenerate: Bool { !allColors.isEmpty && !isLoading }

    func extractColors(from image: UIImage) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                allColors = try await geminiService.extractColors(image)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
