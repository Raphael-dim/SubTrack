//
//  StatsViewModel.swift
//  SubTrack
//
//  Prépare les données de la Vue Statistiques : totaux globaux et répartition
//  par catégorie (pour le donut). S'appuie sur les agrégats du service afin
//  de ne pas dupliquer la logique financière (DRY).
//

import Foundation
import Observation

@Observable
@MainActor
final class StatsViewModel {

    private var subscriptions: [Subscription] = []

    /// Injecte la dernière version des données (appelé par la Vue depuis `@Query`).
    func apply(subscriptions: [Subscription]) {
        self.subscriptions = subscriptions
    }

    // MARK: Sorties dérivées

    var monthlyTotal: Decimal { SubscriptionMetrics.monthlyTotal(for: subscriptions) }
    var yearlyTotal: Decimal { SubscriptionMetrics.yearlyTotal(for: subscriptions) }

    var breakdown: [CategoryBreakdown] { SubscriptionMetrics.breakdownByCategory(for: subscriptions) }

    var activeCount: Int { subscriptions.filter(\.isActive).count }
    var pausedCount: Int { subscriptions.filter { !$0.isActive }.count }

    var hasData: Bool { !subscriptions.filter(\.isActive).isEmpty }

    /// Abonnement actif le plus cher (au mois), pour un encart « point d'attention ».
    var mostExpensive: Subscription? {
        subscriptions
            .filter(\.isActive)
            .max { $0.monthlyEquivalent < $1.monthlyEquivalent }
    }
}
