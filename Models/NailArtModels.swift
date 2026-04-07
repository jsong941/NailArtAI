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

// MARK: - Design Add-On
enum DesignAddOn: String, CaseIterable {
    case frenchTips   = "french_tips"
    case solidColor   = "solid_color"
    case gemstone     = "gemstone"
    case chromePowder = "chrome_powder"

    var displayName: String {
        switch self {
        case .frenchTips:   return "French Tips"
        case .solidColor:   return "Solid Color"
        case .gemstone:     return "Gem Stone"
        case .chromePowder: return "Chrome Powder"
        }
    }

    var emoji: String {
        switch self {
        case .frenchTips:   return "🤍"
        case .solidColor:   return "🎨"
        case .gemstone:     return "💎"
        case .chromePowder: return "✨"
        }
    }

    var description: String {
        switch self {
        case .frenchTips:   return "Classic white tips"
        case .solidColor:   return "Clean, minimal finish"
        case .gemstone:     return "Crystal embellishments"
        case .chromePowder: return "Mirror glazed finish"
        }
    }

    var promptNote: String {
        switch self {
        case .frenchTips:
            return "Add classic elegant white french tips to the nail design."
        case .solidColor:
            return "Keep the design clean and minimal with a smooth solid color application — no patterns or embellishments."
        case .gemstone:
            return "Add decorative rhinestone and crystal gemstone embellishments on accent nails for a luxurious look."
        case .chromePowder:
            return "Apply a chrome mirror powder finish for a glazed, ultra-reflective metallic effect — similar to Hailey Bieber's glazed donut nails."
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
