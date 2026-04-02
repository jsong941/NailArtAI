import SwiftData
import SwiftUI

// MARK: - Codable helpers for JSON storage inside HistorySession

struct StoredColor: Codable {
    let name: String
    let hex: String

    var asNailColor: NailColor { NailColor(name: name, hex: hex) }
}

struct StoredDesign: Codable {
    let emoji: String
    let title: String
    let description: String
    let patternRaw: String

    var asDesignSuggestion: DesignSuggestion {
        DesignSuggestion(
            emoji: emoji,
            title: title,
            description: description,
            pattern: NailPattern(rawValue: patternRaw) ?? .solid
        )
    }
}

// MARK: - SwiftData Model

@Model
class HistorySession {
    var createdAt: Date
    var colorsData: Data
    var designsData: Data

    init(colors: [NailColor], designs: [DesignSuggestion]) {
        createdAt = .now
        let storedColors = colors.map { StoredColor(name: $0.name, hex: $0.hex) }
        let storedDesigns = designs.map {
            StoredDesign(emoji: $0.emoji, title: $0.title, description: $0.description, patternRaw: $0.pattern.rawValue)
        }
        colorsData  = (try? JSONEncoder().encode(storedColors))  ?? Data()
        designsData = (try? JSONEncoder().encode(storedDesigns)) ?? Data()
    }

    var colors: [NailColor] {
        let stored = (try? JSONDecoder().decode([StoredColor].self, from: colorsData)) ?? []
        return stored.map { $0.asNailColor }
    }

    var designs: [DesignSuggestion] {
        let stored = (try? JSONDecoder().decode([StoredDesign].self, from: designsData)) ?? []
        return stored.map { $0.asDesignSuggestion }
    }
}
