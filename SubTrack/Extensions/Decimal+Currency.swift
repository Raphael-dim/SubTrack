//
//  Decimal+Currency.swift
//  SubTrack
//
//  Formatage monétaire centralisé (DRY). On utilise `Decimal` partout pour
//  les montants afin d'éviter les erreurs d'arrondi des `Double`.
//

import Foundation

extension Decimal {

    /// Représentation localisée d'un montant, ex. `"9,99 €"`.
    /// - Parameter currencyCode: code ISO 4217 (ex. `"EUR"`). Par défaut, la
    ///   devise globale choisie dans les Réglages. Le formatage (symbole,
    ///   séparateurs) suit la langue sélectionnée via `AppLocale`.
    func currencyFormatted(currencyCode: String = AppCurrency.current.code) -> String {
        formatted(.currency(code: currencyCode).locale(AppLocale.current))
    }

    /// Conversion sûre vers `Double` pour les composants qui l'exigent
    /// (ex. Swift Charts). À n'utiliser que pour l'affichage, jamais pour du calcul métier.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
