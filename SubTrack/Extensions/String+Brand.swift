//
//  String+Brand.swift
//  SubTrack
//
//  Helpers de présentation de marque : slug (pour retrouver un asset logo) et
//  monogramme (repli visuel quand aucun logo n'est embarqué).
//

import Foundation

extension String {

    /// Slug normalisé sans accents ni ponctuation, ex. « Disney+ » → "disney",
    /// « iCloud+ 200 Go » → "icloud-200-go". Sert à nommer l'asset `logo-<slug>`.
    var brandSlug: String {
        folding(options: .diacriticInsensitive, locale: nil)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    /// Première lettre significative en capitale, ex. « Netflix » → "N".
    /// Utilisée pour la pastille monogramme quand aucun logo n'est disponible.
    var monogram: String {
        let tokens = split { !$0.isLetter && !$0.isNumber }
        guard let first = tokens.first?.first else { return "?" }
        return String(first).uppercased()
    }
}
