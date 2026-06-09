//
//  AppCurrency.swift
//  SubTrack
//
//  Devise d'affichage globale choisie par l'utilisateur, persistée via
//  @AppStorage. Utilisée par défaut pour les totaux agrégés (mois / année).
//  Chaque abonnement conserve par ailleurs sa propre devise.
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
