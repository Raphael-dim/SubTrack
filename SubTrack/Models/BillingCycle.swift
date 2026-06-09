//
//  BillingCycle.swift
//  SubTrack
//
//  Périodicité de facturation d'un abonnement. Enum fermé (KISS) : la liste
//  des cycles est connue et stable. Conforme à `Codable` pour être persisté
//  tel quel comme attribut d'un `@Model` SwiftData.
//

import Foundation

enum BillingCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    /// Libellé affiché à l'utilisateur.
    var displayName: String {
        switch self {
        case .weekly:    L.t("Hebdomadaire")
        case .monthly:   L.t("Mensuel")
        case .quarterly: L.t("Trimestriel")
        case .yearly:    L.t("Annuel")
        }
    }

    /// Nombre de cycles dans une année. Sert de base aux conversions
    /// vers un équivalent mensuel / annuel (source unique de vérité — DRY).
    var occurrencesPerYear: Decimal {
        switch self {
        case .weekly:    52
        case .monthly:   12
        case .quarterly: 4
        case .yearly:    1
        }
    }

    /// Composant calendaire utilisé pour avancer une date de prélèvement.
    var dateComponent: (component: Calendar.Component, value: Int) {
        switch self {
        case .weekly:    (.day, 7)
        case .monthly:   (.month, 1)
        case .quarterly: (.month, 3)
        case .yearly:    (.year, 1)
        }
    }
}
