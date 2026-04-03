import SwiftUI

// MARK: - NailColor Model
struct NailColor: Identifiable {
    let id = UUID()
    let name: String
    let hex: String

    var swiftUIColor: Color { Color(hex: hex) }

    // 3 variations: lighter → base → deeper/saturated
    var series: [Color] {
        guard let uiColor = UIColor(hex: hex) else {
            return [swiftUIColor, swiftUIColor, swiftUIColor]
        }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let lighter = Color(UIColor(hue: h, saturation: max(0, s - 0.25), brightness: min(1, b + 0.2), alpha: 1))
        let deeper  = Color(UIColor(hue: h, saturation: min(1, s + 0.2),  brightness: max(0, b - 0.2), alpha: 1))
        return [lighter, swiftUIColor, deeper]
    }
}

// MARK: - Nail Pattern Type
enum NailPattern: String {
    case solid, ombre, french, glitter, abstract
}

// MARK: - Nail Shape Type
enum NailShapeType: String, CaseIterable {
    case rounded, almond, stiletto, flare

    var displayName: String {
        switch self {
        case .rounded:  return "Round"
        case .almond:   return "Almond"
        case .stiletto: return "Stiletto"
        case .flare:    return "Flare"
        }
    }
}

// MARK: - Design Suggestion Model
struct DesignSuggestion: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let pattern: NailPattern
}
