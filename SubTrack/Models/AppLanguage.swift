//
//  AppLanguage.swift
//  SubTrack
//
//  Langue d'affichage choisie par l'utilisateur, persistée via @AppStorage.
//  Applique une `Locale` à toute l'app (formatage des dates / nombres /
//  devises). `system` = on suit la langue de l'appareil.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case french  = "fr"
    case english = "en"
    case spanish = "es"
    case german  = "de"

    var id: String { rawValue }

    /// Les noms de langues restent affichés dans leur propre langue (endonymes) ;
    /// seul « Système » est localisé.
    var displayName: String {
        switch self {
        case .system:  L.t("Système")
        case .french:  "Français"
        case .english: "English"
        case .spanish: "Español"
        case .german:  "Deutsch"
        }
    }

    /// `nil` → laisse l'app suivre la langue du système.
    var locale: Locale? {
        self == .system ? nil : Locale(identifier: rawValue)
    }

    /// Langue actuellement sélectionnée (préférence utilisateur, défaut système).
    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: PreferenceKey.appLanguage)
        return raw.flatMap(AppLanguage.init) ?? .system
    }
}
