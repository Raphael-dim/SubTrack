//
//  SubscriptionCategory.swift
//  SubTrack
//
//  Référentiel fermé des catégories d'abonnements (décision d'architecture :
//  enum typé plutôt qu'entité SwiftData, cf. cadrage Étape 1). Chaque case
//  porte son libellé, son SF Symbol et sa couleur d'accentuation : la
//  présentation des catégories a ainsi une source unique de vérité (DRY).
//

import SwiftUI

enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case entertainment
    case productivity
    case dailyLife
    case insuranceAndBanking

    var id: String { rawValue }

    /// Libellé affiché à l'utilisateur.
    var displayName: String {
        switch self {
        case .entertainment:       L.t("Divertissement")
        case .productivity:        L.t("Productivité / Tech")
        case .dailyLife:           L.t("Vie quotidienne")
        case .insuranceAndBanking: L.t("Assurances / Banques")
        }
    }

    /// SF Symbol représentatif de la catégorie.
    var symbolName: String {
        switch self {
        case .entertainment:       "play.tv.fill"
        case .productivity:        "desktopcomputer"
        case .dailyLife:           "house.fill"
        case .insuranceAndBanking: "shield.lefthalf.filled"
        }
    }

    /// Couleur d'accentuation de la catégorie (distincte de la couleur de
    /// marque de chaque abonnement). Stockée en hexadécimal pour cohérence
    /// avec `Subscription.accentColorHex`.
    var accentColorHex: String {
        switch self {
        case .entertainment:       "#FF453A" // rouge
        case .productivity:        "#0A84FF" // bleu
        case .dailyLife:           "#30D158" // vert
        case .insuranceAndBanking: "#FF9F0A" // ambre
        }
    }

    /// Couleur SwiftUI dérivée, prête à l'emploi dans les Views.
    var accentColor: Color { Color(hex: accentColorHex) }
}
