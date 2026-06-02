//
//  Color+Hex.swift
//  SubTrack
//
//  Bridge entre les couleurs persistées (stockées en hexadécimal dans
//  SwiftData) et le type `Color` de SwiftUI. Garder la couleur sous forme
//  de `String` évite de rendre `Color` Codable manuellement et reste 100% local.
//

import SwiftUI

extension Color {

    /// Initialise une couleur depuis une chaîne hexadécimale.
    ///
    /// Formats acceptés : `"#RGB"`, `"#RRGGBB"`, `"#AARRGGBB"` (le `#` est optionnel).
    /// Retourne `.clear` si la chaîne est invalide, ce qui évite tout crash
    /// sur des données corrompues tout en restant visuellement neutre.
    init(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&value) else {
            self = .clear
            return
        }

        let r, g, b, a: Double
        switch sanitized.count {
        case 3: // RGB (12-bit)
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double(value & 0xF) / 15
            a = 1
        case 6: // RRGGBB (24-bit)
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        case 8: // AARRGGBB (32-bit)
            a = Double((value >> 24) & 0xFF) / 255
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        default:
            self = .clear
            return
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
