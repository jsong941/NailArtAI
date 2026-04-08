import SwiftUI

// MARK: - NailColor Model
struct NailColor: Identifiable {
    let id = UUID()
    let name: String
    let hex: String

    var swiftUIColor: Color { Color(hex: hex) }

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
    case rounded, almond, stiletto, square

    var displayName: String {
        switch self {
        case .rounded:  return "Round"
        case .almond:   return "Almond"
        case .stiletto: return "Stiletto"
        case .square:   return "Square"
        }
    }
}

// MARK: - Design Add-On
enum DesignAddOn: String, CaseIterable {
    case frenchTip  = "french_tip"
    case solidColor = "solid_color"
    case gemStone   = "gem_stone"
    case finish     = "finish"

    var displayName: String {
        switch self {
        case .frenchTip:  return "French Tip"
        case .solidColor: return "Solid Color"
        case .gemStone:   return "Gem Stone"
        case .finish:     return "Finish"
        }
    }

    var emoji: String {
        switch self {
        case .frenchTip:  return "🤍"
        case .solidColor: return "🎨"
        case .gemStone:   return "💎"
        case .finish:     return "✨"
        }
    }

    var description: String {
        switch self {
        case .frenchTip:  return "Color tips on nude base"
        case .solidColor: return "Clean, minimal finish"
        case .gemStone:   return "Crystal embellishments"
        case .finish:     return "Chrome, glitter or mirror"
        }
    }

    var hasSubmenu: Bool {
        switch self {
        case .solidColor: return false
        default: return true
        }
    }
}

// MARK: - Gem Stone Style
enum GemStoneStyle: String, CaseIterable {
    case minimalism = "minimalism"
    case maximalism = "maximalism"

    var displayName: String {
        switch self {
        case .minimalism: return "Minimalism"
        case .maximalism: return "Maximalism"
        }
    }

    var description: String {
        switch self {
        case .minimalism: return "Max 3 gems per finger"
        case .maximalism: return "Full coverage, bold look"
        }
    }
}

// MARK: - Finish Style
enum FinishStyle: String, CaseIterable {
    case chromePowder = "chrome_powder"
    case glitters     = "glitters"
    case mirrorPowder = "mirror_powder"

    var displayName: String {
        switch self {
        case .chromePowder: return "Chrome Powder"
        case .glitters:     return "Glitters"
        case .mirrorPowder: return "Mirror Powder"
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
