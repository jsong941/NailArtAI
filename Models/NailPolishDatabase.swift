import SwiftUI

// MARK: - Nail Polish Product

struct NailPolishProduct: Identifiable {
    let id = UUID()
    let brand: String
    let name: String
    let hex: String
    let asin: String?

    init(brand: String, name: String, hex: String, asin: String? = nil) {
        self.brand = brand
        self.name = name
        self.hex = hex
        self.asin = asin
    }

    var swiftUIColor: Color { Color(hex: hex) }

    var affiliateURL: URL {
        if let asin {
            return URL(string: "https://www.amazon.com/dp/\(asin)?tag=nailartai01-20")!
        }
        // Use urlQueryAllowed minus & = + so those are percent-encoded in the value
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        let query = "\(brand) \(name) nail polish"
            .addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "https://www.amazon.com/s?k=\(query)&i=beauty&tag=nailartai01-20")!
    }
}

// MARK: - LAB Color (perceptual color matching)

private struct LABColor {
    let L: Double
    let a: Double
    let b: Double

    init?(hex: String) {
        let clean = hex.trimmingCharacters(in: .alphanumerics.inverted)
        guard clean.count == 6,
              let r = UInt8(clean.prefix(2), radix: 16),
              let g = UInt8(clean.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(clean.dropFirst(4).prefix(2), radix: 16) else { return nil }

        // sRGB → linear
        func lin(_ c: UInt8) -> Double {
            let s = Double(c) / 255.0
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        let lr = lin(r); let lg = lin(g); let lb = lin(b)

        // linear RGB → XYZ (D65)
        let x = (lr * 0.4124564 + lg * 0.3575761 + lb * 0.1804375) / 0.95047
        let y = (lr * 0.2126729 + lg * 0.7151522 + lb * 0.0721750) / 1.00000
        let z = (lr * 0.0193339 + lg * 0.1191920 + lb * 0.9503041) / 1.08883

        // XYZ → LAB
        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0/3.0) : (7.787 * t) + (16.0/116.0)
        }
        L = (116.0 * f(y)) - 16.0
        a = 500.0 * (f(x) - f(y))
        self.b = 200.0 * (f(y) - f(z))
    }

    func deltaE(to other: LABColor) -> Double {
        sqrt(pow(L - other.L, 2) + pow(a - other.a, 2) + pow(b - other.b, 2))
    }
}

// MARK: - Color Matching

extension NailPolishProduct {
    static func matches(for hexColor: String, count: Int = 2) -> [NailPolishProduct] {
        guard let target = LABColor(hex: hexColor) else { return [] }
        return all
            .compactMap { polish -> (NailPolishProduct, Double)? in
                guard let lab = LABColor(hex: polish.hex) else { return nil }
                return (polish, target.deltaE(to: lab))
            }
            .sorted { $0.1 < $1.1 }
            .prefix(count)
            .map { $0.0 }
    }
}

// MARK: - Database

extension NailPolishProduct {
    static let all: [NailPolishProduct] = [

        // MARK: OPI
        NailPolishProduct(brand: "OPI", name: "Alpine Snow",               hex: "F5F5F2", asin: "B002D4DQ1Q"),
        NailPolishProduct(brand: "OPI", name: "Bubble Bath",               hex: "F2D4CE", asin: "B000NG889Q"),
        NailPolishProduct(brand: "OPI", name: "Soft Shades Pale to the Chief", hex: "EDD5C8", asin: "B0018BQ5MW"),
        NailPolishProduct(brand: "OPI", name: "Sweet Heart",               hex: "F4A0A8", asin: "B00421Z0ZI"),
        NailPolishProduct(brand: "OPI", name: "Strawberry Margarita",      hex: "F06070", asin: "B000NG46YM"),
        NailPolishProduct(brand: "OPI", name: "Big Apple Red",             hex: "C01228", asin: "B0034E103K"),
        NailPolishProduct(brand: "OPI", name: "An Affair in Red Square",   hex: "9B1B30", asin: "B000V74ET0"),
        NailPolishProduct(brand: "OPI", name: "Malaga Wine",               hex: "722434", asin: "B00421YYXW"),
        NailPolishProduct(brand: "OPI", name: "Lincoln Park After Dark",   hex: "2C1F40", asin: "B000NG46QU"),
        NailPolishProduct(brand: "OPI", name: "Russian Navy",              hex: "1C2B4A", asin: "B0034EAJJ6"),
        NailPolishProduct(brand: "OPI", name: "Yoga-Ta Get This Blue",     hex: "4A90D9", asin: "B00149MWYI"),
        NailPolishProduct(brand: "OPI", name: "Stranger Tides",            hex: "1B7A6E"),
        NailPolishProduct(brand: "OPI", name: "Jade is the New Black",     hex: "3D6B5A"),
        NailPolishProduct(brand: "OPI", name: "Cajun Shrimp",              hex: "E8613A", asin: "B000NG80GM"),
        NailPolishProduct(brand: "OPI", name: "Push & Shove",              hex: "F4A23C"),
        NailPolishProduct(brand: "OPI", name: "Banana Bandana",            hex: "F5D76E"),
        NailPolishProduct(brand: "OPI", name: "Samoan Sand",               hex: "D4B090", asin: "B004223VIK"),
        NailPolishProduct(brand: "OPI", name: "Taupe-less Beach",          hex: "C4A882", asin: "B00HOD8HEM"),
        NailPolishProduct(brand: "OPI", name: "Put It in Neutral",         hex: "C8B8A8", asin: "B012IGWZ1U"),
        NailPolishProduct(brand: "OPI", name: "Black Onyx",                hex: "1A1A1A", asin: "B000NG4778"),

        // MARK: essie
        NailPolishProduct(brand: "essie", name: "Ballet Slippers",         hex: "F7E4E8", asin: "B0030IMVZ6"),
        NailPolishProduct(brand: "essie", name: "Marshmallow",             hex: "F5EFED", asin: "B0006PJR30"),
        NailPolishProduct(brand: "essie", name: "Fiji",                    hex: "F9E0E4", asin: "B00GXVVG58"),
        NailPolishProduct(brand: "essie", name: "Mademoiselle",            hex: "FFD8D0", asin: "B00GXVVDG0"),
        NailPolishProduct(brand: "essie", name: "Romper Room",             hex: "FFB6C4", asin: "B00IABR48W"),
        NailPolishProduct(brand: "essie", name: "Watermelon",              hex: "FC6C85", asin: "B004FGD1L0"),
        NailPolishProduct(brand: "essie", name: "Stop Look & Listen",      hex: "D42828"),
        NailPolishProduct(brand: "essie", name: "Bordeaux",                hex: "4A1020", asin: "B00770OUUM"),
        NailPolishProduct(brand: "essie", name: "Wicked",                  hex: "8B1A2C", asin: "B004FGAXK2"),
        NailPolishProduct(brand: "essie", name: "Fishnet Stockings",       hex: "881822", asin: "B00D92HDDI"),
        NailPolishProduct(brand: "essie", name: "Turquoise & Caicos",      hex: "3BB8B0", asin: "B004FNM20E"),
        NailPolishProduct(brand: "essie", name: "Lapiz of Luxury",         hex: "1B4F8A", asin: "B013BSQX7Q"),
        NailPolishProduct(brand: "essie", name: "Midnight Cami",           hex: "1A1A40", asin: "B00GXW14MW"),
        NailPolishProduct(brand: "essie", name: "Urban Jungle",            hex: "2E7D52", asin: "B00JGX8LV2"),
        NailPolishProduct(brand: "essie", name: "Smokin Hot",              hex: "4A4A4A", asin: "B00GXW0O3C"),
        NailPolishProduct(brand: "essie", name: "Licorice",                hex: "1C1C1C", asin: "B00GXW0VBC"),
        NailPolishProduct(brand: "essie", name: "Sand Tropez",             hex: "C8A882", asin: "B007AWESA4"),
        NailPolishProduct(brand: "essie", name: "Topless & Barefoot",      hex: "C4A07A"),
        NailPolishProduct(brand: "essie", name: "Lilacism",                hex: "C4A8D4", asin: "B00770K6YG"),
        NailPolishProduct(brand: "essie", name: "Perennial Chic",          hex: "9B7EB8"),

        // MARK: Sally Hansen
        NailPolishProduct(brand: "Sally Hansen", name: "White On",         hex: "F8F8F8"),
        NailPolishProduct(brand: "Sally Hansen", name: "Pat on the Black", hex: "1A1A1A"),
        NailPolishProduct(brand: "Sally Hansen", name: "Red Eye",          hex: "CC2020", asin: "B00LHT4OIC"),
        NailPolishProduct(brand: "Sally Hansen", name: "Blushing Beauti",  hex: "F0C0C0"),
        NailPolishProduct(brand: "Sally Hansen", name: "Nude Now",         hex: "C8A888"),
        NailPolishProduct(brand: "Sally Hansen", name: "Pacific Blue",     hex: "2060A8"),
        NailPolishProduct(brand: "Sally Hansen", name: "Jungle Green",     hex: "2A7A3A"),
        NailPolishProduct(brand: "Sally Hansen", name: "Plum Luck",        hex: "6B1F6B"),
        NailPolishProduct(brand: "Sally Hansen", name: "Peach of Cake",    hex: "F0A888"),
        NailPolishProduct(brand: "Sally Hansen", name: "Coral Reef",       hex: "E86848"),
        NailPolishProduct(brand: "Sally Hansen", name: "Gray By Gray",     hex: "888888"),
        NailPolishProduct(brand: "Sally Hansen", name: "Golden Rule",      hex: "C9A84C"),

        // MARK: Olive & June
        NailPolishProduct(brand: "Olive & June", name: "The Nude",         hex: "E8D0BC"),
        NailPolishProduct(brand: "Olive & June", name: "The Cream",        hex: "F5F0EA"),
        NailPolishProduct(brand: "Olive & June", name: "The Red",          hex: "C41830"),
        NailPolishProduct(brand: "Olive & June", name: "The Pink",         hex: "F0A8C0"),
        NailPolishProduct(brand: "Olive & June", name: "The Mauve",        hex: "C8909A"),
        NailPolishProduct(brand: "Olive & June", name: "The Burgundy",     hex: "6B2030"),
        NailPolishProduct(brand: "Olive & June", name: "The Navy",         hex: "1A2840"),
        NailPolishProduct(brand: "Olive & June", name: "The Black",        hex: "1A1A1A"),
        NailPolishProduct(brand: "Olive & June", name: "The Terracotta",   hex: "C4603C"),
        NailPolishProduct(brand: "Olive & June", name: "The Lilac",        hex: "D0B8D8"),
    ]
}
