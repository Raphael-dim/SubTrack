//
//  SubscriptionMetrics.swift
//  SubTrack
//
//  Agrégats financiers purs (sans état ni accès base). Source unique de vérité
//  des totaux et de la répartition (DRY), utilisable par n'importe quel VM
//  sans dépendre d'un `ModelContext` → calculs trivialement testables.
//

import Foundation

/// Résultat d'agrégation par catégorie, prêt pour l'affichage (Vue Stats).
struct CategoryBreakdown: Identifiable, Hashable {
    var category: SubscriptionCategory
    var monthlyTotal: Decimal
    var subscriptionCount: Int
    /// Part du total mensuel global, dans `0...1`.
    var share: Double

    var id: SubscriptionCategory { category }
}

enum SubscriptionMetrics {

    /// N'inclut que les abonnements actifs dans les calculs.
    static func activeOnly(_ subscriptions: [Subscription]) -> [Subscription] {
        subscriptions.filter(\.isActive)
    }

    static func monthlyTotal(for subscriptions: [Subscription]) -> Decimal {
        activeOnly(subscriptions).reduce(0) { $0 + $1.monthlyEquivalent }
    }

    static func yearlyTotal(for subscriptions: [Subscription]) -> Decimal {
        activeOnly(subscriptions).reduce(0) { $0 + $1.yearlyEquivalent }
    }

    static func breakdownByCategory(for subscriptions: [Subscription]) -> [CategoryBreakdown] {
        let active = activeOnly(subscriptions)
        let grandTotal = active.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
        let grouped = Dictionary(grouping: active, by: \.category)

        return grouped
            .map { category, items in
                let monthly = items.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
                let share = grandTotal > 0 ? (monthly / grandTotal).doubleValue : 0
                return CategoryBreakdown(
                    category: category,
                    monthlyTotal: monthly,
                    subscriptionCount: items.count,
                    share: share
                )
            }
            .sorted { $0.monthlyTotal > $1.monthlyTotal }
    }
}
