//
//  AppCurrency.swift
//  SubTrack
//
//  Devise unique de l'app, choisie par l'utilisateur et persistée via
//  @AppStorage. L'app est mono-devise : cette devise s'applique partout
//  (montants des abonnements comme totaux agrégés).
//

import Foundation

enum AppCurrency: String, CaseIterable, Identifiable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case chf = "CHF"
    case cad = "CAD"
    case jpy = "JPY"

    var id: String { rawValue }

    /// Code ISO 4217 transmis au formatage monétaire.
    var code: String { rawValue }

    /// Symbole court de la devise (ex. « € », « $ », « CHF »).
    var symbol: String {
        switch self {
        case .eur:        "€"
        case .usd, .cad:  "$"
        case .gbp:        "£"
        case .chf:        "CHF"
        case .jpy:        "¥"
        }
    }

    var displayName: String {
        switch self {
        case .eur: L.t("Euro (€)")
        case .usd: L.t("Dollar US ($)")
        case .gbp: L.t("Livre sterling (£)")
        case .chf: L.t("Franc suisse (CHF)")
        case .cad: L.t("Dollar canadien ($ CA)")
        case .jpy: L.t("Yen (¥)")
        }
    }

    /// Devise applicable globalement (préférence utilisateur, défaut EUR).
    static var current: AppCurrency {
        let raw = UserDefaults.standard.string(forKey: PreferenceKey.currencyCode)
        return raw.flatMap(AppCurrency.init) ?? .eur
    }
}
