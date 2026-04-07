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

        // MARK: OPI — Whites / Sheer
        NailPolishProduct(brand: "OPI", name: "Alpine Snow",                    hex: "F5F5F2", asin: "B002D4DQ1Q"),
        NailPolishProduct(brand: "OPI", name: "Bubble Bath",                    hex: "F2D4CE", asin: "B000NG889Q"),
        NailPolishProduct(brand: "OPI", name: "Soft Shades Pale to the Chief",  hex: "EDD5C8", asin: "B0018BQ5MW"),
        NailPolishProduct(brand: "OPI", name: "Coney Island Cotton Candy",      hex: "F5DADE", asin: "B00421YYYQ"),
        NailPolishProduct(brand: "OPI", name: "Mimosas for Mr. & Mrs.",         hex: "F5D0C0", asin: "B000NGATPW"),

        // MARK: OPI — Pinks
        NailPolishProduct(brand: "OPI", name: "Sweet Heart",                    hex: "F4A0A8", asin: "B00421Z0ZI"),
        NailPolishProduct(brand: "OPI", name: "Tickle My France-y",             hex: "F2C4CE", asin: "B001DYJ544"),
        NailPolishProduct(brand: "OPI", name: "Passion",                        hex: "F5C6C8", asin: "B002D4L046"),
        NailPolishProduct(brand: "OPI", name: "Rosy Future",                    hex: "F0B8C0", asin: "B000NGCVZS"),
        NailPolishProduct(brand: "OPI", name: "Mod About You",                  hex: "F5A8C0", asin: "B000NG6D7K"),
        NailPolishProduct(brand: "OPI", name: "Kiss Me I'm Brazilian",          hex: "F4A7C0", asin: "B006JUVPSG"),
        NailPolishProduct(brand: "OPI", name: "Elephantastic Pink",             hex: "FF69A0", asin: "B00149NUO4"),
        NailPolishProduct(brand: "OPI", name: "Two Timing the Zones",           hex: "FF5090", asin: "B077XCVY2G"),
        NailPolishProduct(brand: "OPI", name: "Strawberry Margarita",           hex: "F06070", asin: "B000NG46YM"),

        // MARK: OPI — Reds
        NailPolishProduct(brand: "OPI", name: "OPI Red",                        hex: "CC0000", asin: "B00421Z0ZS"),
        NailPolishProduct(brand: "OPI", name: "I Stop for Red",                 hex: "CC0000", asin: "B00188CH36"),
        NailPolishProduct(brand: "OPI", name: "Big Apple Red",                  hex: "C01228", asin: "B0034E103K"),
        NailPolishProduct(brand: "OPI", name: "Coca-Cola Red",                  hex: "E2001A", asin: "B000NG90NE"),
        NailPolishProduct(brand: "OPI", name: "Red Hot Rio",                    hex: "CC2200", asin: "B001RV9FJS"),
        NailPolishProduct(brand: "OPI", name: "Charged Up Cherry",              hex: "E8005A", asin: "B000NG84G8"),

        // MARK: OPI — Burgundy / Dark Red
        NailPolishProduct(brand: "OPI", name: "An Affair in Red Square",        hex: "9B1B30", asin: "B000V74ET0"),
        NailPolishProduct(brand: "OPI", name: "Malaga Wine",                    hex: "722434", asin: "B00421YYXW"),
        NailPolishProduct(brand: "OPI", name: "You Don't Know Jacques!",        hex: "705850", asin: "B001DYFFCU"),
        NailPolishProduct(brand: "OPI", name: "Squeaker of the House",          hex: "604020", asin: "B003IKRHTQ"),
        NailPolishProduct(brand: "OPI", name: "Skull & Glossbones",             hex: "302820", asin: "B01N2TT696"),

        // MARK: OPI — Oranges / Corals
        NailPolishProduct(brand: "OPI", name: "Cajun Shrimp",                   hex: "E8613A", asin: "B000NG80GM"),
        NailPolishProduct(brand: "OPI", name: "A Good Man-darin is Hard to Find", hex: "E07030", asin: "B0035Y80JQ"),
        NailPolishProduct(brand: "OPI", name: "Toucan Do It If You Try",        hex: "E06030", asin: "B001G7HMEI"),
        NailPolishProduct(brand: "OPI", name: "Crawfishin' for a Compliment",   hex: "E09060", asin: "B004756YJA"),
        NailPolishProduct(brand: "OPI", name: "Suzi Nails New Orleans",         hex: "E8A0A0", asin: "B00JRHT9Q8"),

        // MARK: OPI — Yellows / Greens
        NailPolishProduct(brand: "OPI", name: "Banana Bandana",                 hex: "F5D76E"),
        NailPolishProduct(brand: "OPI", name: "Push & Shove",                   hex: "F4A23C"),
        NailPolishProduct(brand: "OPI", name: "Exotic Birds Do Not Tweet",      hex: "D4B040", asin: "B01NH7QALN"),
        NailPolishProduct(brand: "OPI", name: "Stranger Tides",                 hex: "1B7A6E"),
        NailPolishProduct(brand: "OPI", name: "Jade is the New Black",          hex: "3D6B5A"),
        NailPolishProduct(brand: "OPI", name: "Espresso Your Style",            hex: "604030", asin: "B01N4FWUZC"),

        // MARK: OPI — Blues / Purples
        NailPolishProduct(brand: "OPI", name: "Yoga-Ta Get This Blue",          hex: "4A90D9", asin: "B00149MWYI"),
        NailPolishProduct(brand: "OPI", name: "No Room for the Blues",          hex: "2050C0", asin: "B0027105BY"),
        NailPolishProduct(brand: "OPI", name: "Russian Navy",                   hex: "1C2B4A", asin: "B0034EAJJ6"),
        NailPolishProduct(brand: "OPI", name: "Lincoln Park After Dark",        hex: "2C1F40", asin: "B000NG46QU"),
        NailPolishProduct(brand: "OPI", name: "You're Such a Budapest",         hex: "A090D0", asin: "B00BEDJUQ2"),
        NailPolishProduct(brand: "OPI", name: "Eurso Euro",                     hex: "6070C0", asin: "B00014358E"),

        // MARK: OPI — Nudes / Neutrals
        NailPolishProduct(brand: "OPI", name: "Samoan Sand",                    hex: "D4B090", asin: "B004223VIK"),
        NailPolishProduct(brand: "OPI", name: "Taupe-less Beach",               hex: "C4A882", asin: "B00HOD8HEM"),
        NailPolishProduct(brand: "OPI", name: "Put It in Neutral",              hex: "C8B8A8", asin: "B012IGWZ1U"),
        NailPolishProduct(brand: "OPI", name: "Don't Bossa Nova Me Around",     hex: "C8A898", asin: "B00HT9VL3A"),
        NailPolishProduct(brand: "OPI", name: "Tiramisu for Two",               hex: "C8A87A", asin: "B00164BK4E"),
        NailPolishProduct(brand: "OPI", name: "Dulce de Leche",                 hex: "C8A070", asin: "B00421X2SU"),
        NailPolishProduct(brand: "OPI", name: "Barefoot in Barcelona",          hex: "C89060", asin: "B00421X35C"),
        NailPolishProduct(brand: "OPI", name: "Be There in a Prosecco",         hex: "D4B898", asin: "B012IGYENM"),
        NailPolishProduct(brand: "OPI", name: "Humidi-Tea",                     hex: "D4B8A0", asin: "B00G459OR0"),
        NailPolishProduct(brand: "OPI", name: "Do You Take Lei Away?",          hex: "D4B896", asin: "B00NM1LBZ2"),
        NailPolishProduct(brand: "OPI", name: "My Very First Knockwurst",       hex: "E8C8C0", asin: "B008YFX9KG"),
        NailPolishProduct(brand: "OPI", name: "Don't Pretzel My Buttons",       hex: "C8A060", asin: "B008V9P4GW"),
        NailPolishProduct(brand: "OPI", name: "Step Right Up!",                 hex: "E8C0B0", asin: "B004UBD36I"),
        NailPolishProduct(brand: "OPI", name: "Somewhere Over the Rainbow Mountains", hex: "F0B0C0", asin: "B07D5NJVXF"),

        // MARK: OPI — Blacks / Grays
        NailPolishProduct(brand: "OPI", name: "Black Onyx",                     hex: "1A1A1A", asin: "B000NG4778"),

        // MARK: essie — Whites / Sheers
        NailPolishProduct(brand: "essie", name: "Ballet Slippers",              hex: "F7E4E8", asin: "B0030IMVZ6"),
        NailPolishProduct(brand: "essie", name: "Marshmallow",                  hex: "F5EFED", asin: "B0006PJR30"),
        NailPolishProduct(brand: "essie", name: "blanc",                        hex: "F5F0EB", asin: "B00GXVV07M"),
        NailPolishProduct(brand: "essie", name: "Fiji",                         hex: "F9E0E4", asin: "B00GXVVG58"),
        NailPolishProduct(brand: "essie", name: "vanity fairest",               hex: "F0C8C8", asin: "B00770KI4Y"),
        NailPolishProduct(brand: "essie", name: "birthday girl",                hex: "F2C0CC", asin: "B07KZDPNPV"),
        NailPolishProduct(brand: "essie", name: "peak show",                    hex: "E8C4CB", asin: "B0166R1FE0"),

        // MARK: essie — Pinks
        NailPolishProduct(brand: "essie", name: "Mademoiselle",                 hex: "FFD8D0", asin: "B00GXVVDG0"),
        NailPolishProduct(brand: "essie", name: "Romper Room",                  hex: "FFB6C4", asin: "B00IABR48W"),
        NailPolishProduct(brand: "essie", name: "angora cardi",                 hex: "C09090", asin: "B004FG9ZJ2"),
        NailPolishProduct(brand: "essie", name: "pink parka",                   hex: "D8708A", asin: "B003O9N4JS"),
        NailPolishProduct(brand: "essie", name: "Lounge Lover",                 hex: "F0A0C8", asin: "B01AUOTSVW"),
        NailPolishProduct(brand: "essie", name: "Cascade Cool",                 hex: "E0A8B8", asin: "B01766QH2U"),
        NailPolishProduct(brand: "essie", name: "hubby for dessert",            hex: "C8A0C0", asin: "B00VK5VJQS"),

        // MARK: essie — Reds
        NailPolishProduct(brand: "essie", name: "Watermelon",                   hex: "FC6C85", asin: "B004FGD1L0"),
        NailPolishProduct(brand: "essie", name: "lollipop",                     hex: "C82040", asin: "B00770K7QI"),
        NailPolishProduct(brand: "essie", name: "clambake",                     hex: "D4462A", asin: "B004FGD0VG"),
        NailPolishProduct(brand: "essie", name: "bachelorette bash",            hex: "D6226E", asin: "B00GXVVNG0"),
        NailPolishProduct(brand: "essie", name: "cute as a button",             hex: "E86040", asin: "B00GXVX0LQ"),
        NailPolishProduct(brand: "essie", name: "Stop Look & Listen",           hex: "D42828"),
        NailPolishProduct(brand: "essie", name: "eternal optimist",             hex: "C8786A", asin: "B00GJ7DWKI"),

        // MARK: essie — Burgundy / Dark
        NailPolishProduct(brand: "essie", name: "Bordeaux",                     hex: "4A1020", asin: "B00770OUUM"),
        NailPolishProduct(brand: "essie", name: "Wicked",                       hex: "8B1A2C", asin: "B004FGAXK2"),
        NailPolishProduct(brand: "essie", name: "Fishnet Stockings",            hex: "881822", asin: "B00D92HDDI"),
        NailPolishProduct(brand: "essie", name: "in the lobby",                 hex: "803050", asin: "B0140H1A70"),
        NailPolishProduct(brand: "essie", name: "mink muffs",                   hex: "A08070", asin: "B004FG85XE"),
        NailPolishProduct(brand: "essie", name: "After School Boy Blazer",      hex: "202840", asin: "B00O4Q31SE"),

        // MARK: essie — Blues / Teals
        NailPolishProduct(brand: "essie", name: "Turquoise & Caicos",           hex: "3BB8B0", asin: "B004FNM20E"),
        NailPolishProduct(brand: "essie", name: "in the cab-ana",               hex: "60C8C0", asin: "B00SH90TBG"),
        NailPolishProduct(brand: "essie", name: "where's my chauffeur",         hex: "40A090", asin: "B008V1I5GG"),
        NailPolishProduct(brand: "essie", name: "mint candy apple",             hex: "80D0B0", asin: "B00GJ8OX3C"),
        NailPolishProduct(brand: "essie", name: "find me an oasis",             hex: "A0D0E0", asin: "B00O4Q33AK"),
        NailPolishProduct(brand: "essie", name: "bikini so teeny",              hex: "7090D0", asin: "B00B9FSWNC"),
        NailPolishProduct(brand: "essie", name: "Lapiz of Luxury",              hex: "1B4F8A", asin: "B013BSQX7Q"),
        NailPolishProduct(brand: "essie", name: "go overboard",                 hex: "2050A0", asin: "B007X7MDA8"),
        NailPolishProduct(brand: "essie", name: "blue rhapsody",                hex: "3060C0", asin: "B00915D674"),
        NailPolishProduct(brand: "essie", name: "spring in your step",          hex: "C0D8E0", asin: "B083YFSXG8"),
        NailPolishProduct(brand: "essie", name: "first timer",                  hex: "8FBF8A", asin: "B00ATDTYNM"),

        // MARK: essie — Purples
        NailPolishProduct(brand: "essie", name: "Lilacism",                     hex: "C4A8D4", asin: "B00770K6YG"),
        NailPolishProduct(brand: "essie", name: "Perennial Chic",               hex: "9B7EB8"),
        NailPolishProduct(brand: "essie", name: "style cartel",                 hex: "1830A0", asin: "B00KYU4MV4"),
        NailPolishProduct(brand: "essie", name: "Butler Please",                hex: "2040A0", asin: "B00GJ782FI"),
        NailPolishProduct(brand: "essie", name: "Midnight Cami",                hex: "1A1A40", asin: "B00GXW14MW"),
        NailPolishProduct(brand: "essie", name: "dressed to the nines",         hex: "6040A0", asin: "B072MLLWDD"),
        NailPolishProduct(brand: "essie", name: "sole mate",                    hex: "5C2060", asin: "B00A3B3LC0"),
        NailPolishProduct(brand: "essie", name: "the girls are out",            hex: "C04080", asin: "B00BXS9PFE"),

        // MARK: essie — Greens
        NailPolishProduct(brand: "essie", name: "Urban Jungle",                 hex: "2E7D52", asin: "B00JGX8LV2"),
        NailPolishProduct(brand: "essie", name: "Vested Interest",              hex: "506040", asin: "B00G6JOZK0"),
        NailPolishProduct(brand: "essie", name: "Maximillian Strasse Her",      hex: "A0A890", asin: "B0080CSKEI"),
        NailPolishProduct(brand: "essie", name: "summit of style",              hex: "C0A840", asin: "B00SH90T4I"),
        NailPolishProduct(brand: "essie", name: "nothing else metals",          hex: "8080C0", asin: "B007ZR2S7E"),

        // MARK: essie — Nudes / Neutrals
        NailPolishProduct(brand: "essie", name: "Sand Tropez",                  hex: "C8A882", asin: "B007AWESA4"),
        NailPolishProduct(brand: "essie", name: "Topless & Barefoot",           hex: "C4A07A"),
        NailPolishProduct(brand: "essie", name: "sugar daddy",                  hex: "F0D0B8", asin: "B004FGAX52"),
        NailPolishProduct(brand: "essie", name: "spin the bottle",              hex: "D4B89A", asin: "B00IKEWS7G"),
        NailPolishProduct(brand: "essie", name: "go go geisha",                 hex: "E8C8D0", asin: "B01MEH3HV6"),
        NailPolishProduct(brand: "essie", name: "lady like",                    hex: "C898A0", asin: "B005FM2B8M"),
        NailPolishProduct(brand: "essie", name: "penny talk",                   hex: "B87040", asin: "B00FFJ578G"),
        NailPolishProduct(brand: "essie", name: "cocktails & coconuts",         hex: "C0B090", asin: "B00O4Q33IW"),
        NailPolishProduct(brand: "essie", name: "Petal Pushers",                hex: "9898B0", asin: "B01766QBXK"),
        NailPolishProduct(brand: "essie", name: "Master Plan",                  hex: "A0A0A0", asin: "B004FG9YXE"),

        // MARK: essie — Blacks / Grays
        NailPolishProduct(brand: "essie", name: "Smokin Hot",                   hex: "4A4A4A", asin: "B00GXW0O3C"),
        NailPolishProduct(brand: "essie", name: "Licorice",                     hex: "1C1C1C", asin: "B00GXW0VBC"),
        NailPolishProduct(brand: "essie", name: "chinchilly",                   hex: "9B9B9B", asin: "B00770OW6Y"),
        NailPolishProduct(brand: "essie", name: "no place like chrome",         hex: "C0C0C0", asin: "B00BR2BP9K"),

        // MARK: Zoya — Whites / Sheers
        NailPolishProduct(brand: "Zoya", name: "Purity",                        hex: "F8F8F8", asin: "B002YK53ZG"),
        NailPolishProduct(brand: "Zoya", name: "Irene",                         hex: "E8C8B0", asin: "B004ARRKRU"),
        NailPolishProduct(brand: "Zoya", name: "Rue",                           hex: "E8C0C0", asin: "B01M6VZED8"),

        // MARK: Zoya — Pinks
        NailPolishProduct(brand: "Zoya", name: "Gilda",                         hex: "E8A0B0", asin: "B003FIV0HG"),
        NailPolishProduct(brand: "Zoya", name: "Phoebe",                        hex: "F0A0C0", asin: "B006WTWH0O"),
        NailPolishProduct(brand: "Zoya", name: "Wendy",                         hex: "F0B8A0", asin: "B01M4P97W9"),
        NailPolishProduct(brand: "Zoya", name: "Presley",                       hex: "B09090", asin: "B0758CBS24"),
        NailPolishProduct(brand: "Zoya", name: "Waverly",                       hex: "C87890", asin: "B01LXMN6XD"),
        NailPolishProduct(brand: "Zoya", name: "Ali",                           hex: "F080A8", asin: "B002YK54WS"),
        NailPolishProduct(brand: "Zoya", name: "Rooney",                        hex: "D06080", asin: "B01M7VQ7M9"),

        // MARK: Zoya — Reds
        NailPolishProduct(brand: "Zoya", name: "America",                       hex: "C82020", asin: "B002YK54VO"),
        NailPolishProduct(brand: "Zoya", name: "Carmen",                        hex: "C03020", asin: "B002YK52OS"),
        NailPolishProduct(brand: "Zoya", name: "Reagan",                        hex: "C02060", asin: "B007PSY0WE"),
        NailPolishProduct(brand: "Zoya", name: "Chantal",                       hex: "C84060", asin: "B00J2CC5EG"),
        NailPolishProduct(brand: "Zoya", name: "Pepper",                        hex: "A01020", asin: "B00E91NMN8"),

        // MARK: Zoya — Burgundy / Dark
        NailPolishProduct(brand: "Zoya", name: "Quinn",                         hex: "802050", asin: "B002YK54DW"),
        NailPolishProduct(brand: "Zoya", name: "Margo",                         hex: "903060", asin: "B01MAVQIUJ"),
        NailPolishProduct(brand: "Zoya", name: "Odette",                        hex: "703050", asin: "B01M5AHD48"),
        NailPolishProduct(brand: "Zoya", name: "Dovima",                        hex: "404040", asin: "B002G3K1UI"),
        NailPolishProduct(brand: "Zoya", name: "Storm",                         hex: "505060", asin: "B009R4P528"),

        // MARK: Zoya — Purples
        NailPolishProduct(brand: "Zoya", name: "Iris",                          hex: "6030A0", asin: "B01609KGB2"),
        NailPolishProduct(brand: "Zoya", name: "Savita",                        hex: "8040A0", asin: "B004ARTXB6"),
        NailPolishProduct(brand: "Zoya", name: "Harlow",                        hex: "9060A0", asin: "B00O986P9E"),
        NailPolishProduct(brand: "Zoya", name: "Bubbly",                        hex: "D080C0", asin: "B00KZ8YTF4"),
        NailPolishProduct(brand: "Zoya", name: "Sansa",                         hex: "5C2060", asin: "B01MA2Z64L"),

        // MARK: Zoya — Blues / Greens
        NailPolishProduct(brand: "Zoya", name: "Dream",                         hex: "6080C0", asin: "B01M2ASJDM"),
        NailPolishProduct(brand: "Zoya", name: "Yummy",                         hex: "60A0C0", asin: "B002YK547S"),
        NailPolishProduct(brand: "Zoya", name: "Wednesday",                     hex: "4060A0", asin: "B008S6JOAK"),
        NailPolishProduct(brand: "Zoya", name: "Zuza",                          hex: "4080C0", asin: "B007PSY25Y"),
        NailPolishProduct(brand: "Zoya", name: "Rocky",                         hex: "4080A0", asin: "B00CMMYEHY"),
        NailPolishProduct(brand: "Zoya", name: "Noot",                          hex: "304850", asin: "B0094JEMUM"),
        NailPolishProduct(brand: "Zoya", name: "Tilda",                         hex: "70A040", asin: "B00KNY0CWO"),
        NailPolishProduct(brand: "Zoya", name: "Frida",                         hex: "206060", asin: "B01M3W6LXL"),

        // MARK: Zoya — Nudes / Neutrals
        NailPolishProduct(brand: "Zoya", name: "Abby",                          hex: "D0B090", asin: "B071V7KJ29"),
        NailPolishProduct(brand: "Zoya", name: "Laurel",                        hex: "D0C0A0", asin: "B01D1SSWCA"),
        NailPolishProduct(brand: "Zoya", name: "Cassedy",                       hex: "C0B0B8", asin: "B01M3P2OD2"),

        // MARK: Sally Hansen
        NailPolishProduct(brand: "Sally Hansen", name: "White On",              hex: "F8F8F8"),
        NailPolishProduct(brand: "Sally Hansen", name: "Pat on the Black",      hex: "1A1A1A"),
        NailPolishProduct(brand: "Sally Hansen", name: "Red Eye",               hex: "CC2020", asin: "B00LHT4OIC"),
        NailPolishProduct(brand: "Sally Hansen", name: "Blushing Beauti",       hex: "F0C0C0"),
        NailPolishProduct(brand: "Sally Hansen", name: "Nude Now",              hex: "C8A888"),
        NailPolishProduct(brand: "Sally Hansen", name: "Pacific Blue",          hex: "2060A8"),
        NailPolishProduct(brand: "Sally Hansen", name: "Jungle Green",          hex: "2A7A3A"),
        NailPolishProduct(brand: "Sally Hansen", name: "Plum Luck",             hex: "6B1F6B"),
        NailPolishProduct(brand: "Sally Hansen", name: "Peach of Cake",         hex: "F0A888"),
        NailPolishProduct(brand: "Sally Hansen", name: "Coral Reef",            hex: "E86848"),
        NailPolishProduct(brand: "Sally Hansen", name: "Gray By Gray",          hex: "888888"),
        NailPolishProduct(brand: "Sally Hansen", name: "Golden Rule",           hex: "C9A84C"),

        // MARK: Olive & June
        NailPolishProduct(brand: "Olive & June", name: "The Nude",              hex: "E8D0BC"),
        NailPolishProduct(brand: "Olive & June", name: "The Cream",             hex: "F5F0EA"),
        NailPolishProduct(brand: "Olive & June", name: "The Red",               hex: "C41830"),
        NailPolishProduct(brand: "Olive & June", name: "The Pink",              hex: "F0A8C0"),
        NailPolishProduct(brand: "Olive & June", name: "The Mauve",             hex: "C8909A"),
        NailPolishProduct(brand: "Olive & June", name: "The Burgundy",          hex: "6B2030"),
        NailPolishProduct(brand: "Olive & June", name: "The Navy",              hex: "1A2840"),
        NailPolishProduct(brand: "Olive & June", name: "The Black",             hex: "1A1A1A"),
        NailPolishProduct(brand: "Olive & June", name: "The Terracotta",        hex: "C4603C"),
        NailPolishProduct(brand: "Olive & June", name: "The Lilac",             hex: "D0B8D8"),
    ]
}
