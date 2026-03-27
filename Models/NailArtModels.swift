import SwiftUI

// MARK: - NailColor Model
struct NailColor: Identifiable {
    let id = UUID()
    let name: String
    let hex: String

    var swiftUIColor: Color {
        Color(hex: hex)
    }
}

// MARK: - Design Suggestion Model
struct DesignSuggestion: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
}

// MARK: - Analysis Result Model
struct AnalysisResult {
    let colors: [NailColor]
    let suggestions: [DesignSuggestion]
}
