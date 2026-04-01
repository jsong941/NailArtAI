import SwiftUI
import Combine

@MainActor
class ColorSelectionViewModel: ObservableObject {
    @Published var allColors: [NailColor] = []
    @Published var visibleCount: Int = 2
    @Published var selectedIDs: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let geminiService = GeminiService()

    var visibleColors: [NailColor] {
        Array(allColors.prefix(visibleCount))
    }

    var canShowMore: Bool {
        visibleCount < min(4, allColors.count)
    }

    var selectedColors: [NailColor] {
        // Preserve original order
        allColors.filter { selectedIDs.contains($0.id) }
    }

    var canGenerateDesigns: Bool {
        !selectedIDs.isEmpty && !isLoading
    }

    func extractColors(from image: UIImage) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let colors = try await geminiService.extractColors(image)
                allColors = colors
                // Auto-select the most dominant color
                if let first = colors.first {
                    selectedIDs = [first.id]
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func toggle(_ color: NailColor) {
        if selectedIDs.contains(color.id) {
            selectedIDs.remove(color.id)
        } else if selectedIDs.count < 2 {
            selectedIDs.insert(color.id)
        }
    }

    func showNextColor() {
        guard canShowMore else { return }
        visibleCount += 1
    }
}
