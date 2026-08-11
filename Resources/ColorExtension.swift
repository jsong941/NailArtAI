import SwiftUI
import UIKit

extension UIImage {
    func resizedForAPI(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        guard scale < 1 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int), hex.count == 6 else { return nil }
        self.init(
            red: CGFloat(int >> 16) / 255,
            green: CGFloat(int >> 8 & 0xFF) / 255,
            blue: CGFloat(int & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    static let appBackground = Color(hex: "FCFAF8")
    static let appAccent     = Color(hex: "C9A84C")
    static let accentSoft    = Color(hex: "F5F0E8")
    static let textPrimary   = Color(hex: "2C2925")
    static let textSecondary = Color(hex: "8E8A83")
    static let textBody      = Color(hex: "6B6760")
    static let divider       = Color(hex: "E8E4DF")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
