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

// MARK: - SwiftData Models

@Model
class FavoriteDesign {
    var savedAt: Date
    var emoji: String
    var title: String
    var designDescription: String
    var patternRaw: String
    var colorsData: Data
    var generatedImageData: Data?

    init(suggestion: DesignSuggestion, colors: [NailColor], generatedImageData: Data? = nil) {
        savedAt = .now
        emoji = suggestion.emoji
        title = suggestion.title
        designDescription = suggestion.description
        patternRaw = suggestion.pattern.rawValue
        let stored = colors.map { StoredColor(name: $0.name, hex: $0.hex) }
        colorsData = (try? JSONEncoder().encode(stored)) ?? Data()
        self.generatedImageData = generatedImageData
    }

    var generatedImage: UIImage? {
        guard let data = generatedImageData else { return nil }
        return UIImage(data: data)
    }

    var colors: [NailColor] {
        let stored = (try? JSONDecoder().decode([StoredColor].self, from: colorsData)) ?? []
        return stored.map { $0.asNailColor }
    }

    var asDesignSuggestion: DesignSuggestion {
        DesignSuggestion(
            emoji: emoji,
            title: title,
            description: designDescription,
            pattern: NailPattern(rawValue: patternRaw) ?? .solid
        )
    }
}

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
