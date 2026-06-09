//
//  Localization.swift
//  SubTrack
//
//  Localisation pilotée par la langue choisie dans les Réglages, avec
//  changement à chaud (sans relancer l'app). Chaque clé est la chaîne source
//  française ; on la résout depuis le `.lproj` de la langue sélectionnée. En
//  mode « Système », on retombe sur le bundle principal (langue de l'appareil).
//  Les vues SwiftUI reçoivent ainsi du texte déjà résolu (`Text(L.t("…"))`),
//  ce qui rend le basculement déterministe quelle que soit la version d'iOS.
//

import Foundation

enum L {

    /// Bundle de la langue sélectionnée, ou `nil` pour suivre le système.
    private static var selectedBundle: Bundle? {
        let language = AppLanguage.current
        guard language != .system,
              let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return nil
        }
        return bundle
    }

    /// Chaîne localisée pour `key` (la clé est la chaîne source française).
    static func t(_ key: String) -> String {
        (selectedBundle ?? .main).localizedString(forKey: key, value: key, table: nil)
    }

    /// Variante avec arguments de format (`%@`, `%d`…), formatés selon la locale.
    static func t(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: AppLocale.current, arguments: arguments)
    }
}

/// Source unique de la `Locale` applicable au formatage (dates, nombres,
/// devises). Suit la langue choisie, ou l'appareil en mode « Système ».
enum AppLocale {
    static var current: Locale {
        AppLanguage.current.locale ?? .autoupdatingCurrent
    }
}

extension Date {
    /// Date abrégée (ex. « 6 juin 2026 ») formatée selon la langue choisie.
    func appFormattedDate() -> String {
        formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(AppLocale.current))
    }
}
