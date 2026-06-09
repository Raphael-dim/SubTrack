//
//  Decimal+Currency.swift
//  SubTrack
//
//  Formatage monétaire centralisé (DRY). On utilise `Decimal` partout pour
//  les montants afin d'éviter les erreurs d'arrondi des `Double`.
//

import Foundation

extension Decimal {

    /// Représentation localisée d'un montant dans la devise de l'app, ex. `"9,99 €"`.
    /// L'app est mono-devise : la devise et le formatage (symbole, séparateurs)
    /// suivent les Réglages via `AppCurrency.current` et `AppLocale.current`.
    func currencyFormatted() -> String {
        formatted(.currency(code: AppCurrency.current.code).locale(AppLocale.current))
    }

    /// Conversion sûre vers `Double` pour les composants qui l'exigent
    /// (ex. Swift Charts). À n'utiliser que pour l'affichage, jamais pour du calcul métier.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
