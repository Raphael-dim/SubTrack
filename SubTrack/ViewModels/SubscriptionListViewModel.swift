//
//  SubscriptionListViewModel.swift
//  SubTrack
//
//  Logique de présentation de la liste : recherche, filtre par catégorie,
//  tri, et totaux. La Vue reste « bête » et se contente de lier ces états.
//  Les données brutes proviennent d'un `@Query` côté Vue et sont injectées
//  ici via `apply(subscriptions:)` (la VM ne touche pas SwiftData directement).
//

import Foundation
import Observation

@Observable
@MainActor
final class SubscriptionListViewModel {

    enum SortOption: String, CaseIterable, Identifiable {
        case nextBilling
        case priceDescending
        case nameAscending

        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .nextBilling:     L.t("Prochain prélèvement")
            case .priceDescending: L.t("Prix décroissant")
            case .nameAscending:   L.t("Nom (A→Z)")
            }
        }
    }

    // MARK: État UI

    var searchText: String = ""
    var selectedCategory: SubscriptionCategory? = nil
    var sortOption: SortOption = .nextBilling

    // MARK: Données

    private var allSubscriptions: [Subscription] = []

    /// Injecte la dernière version des données (appelé par la Vue depuis `@Query`).
    func apply(subscriptions: [Subscription]) {
        allSubscriptions = subscriptions
    }

    // MARK: Sorties dérivées

    /// Liste filtrée + triée, prête à être affichée.
    var displayedSubscriptions: [Subscription] {
        allSubscriptions
            .filter(matchesCategory)
            .filter(matchesSearch)
            .sorted(by: sortComparator)
    }

    var monthlyTotal: Decimal { SubscriptionMetrics.monthlyTotal(for: allSubscriptions) }
    var yearlyTotal: Decimal { SubscriptionMetrics.yearlyTotal(for: allSubscriptions) }
    var activeCount: Int { allSubscriptions.filter(\.isActive).count }

    var isEmpty: Bool { allSubscriptions.isEmpty }
    var hasNoResults: Bool { !allSubscriptions.isEmpty && displayedSubscriptions.isEmpty }

    // MARK: Filtrage / tri

    private func matchesCategory(_ subscription: Subscription) -> Bool {
        guard let selectedCategory else { return true }
        return subscription.category == selectedCategory
    }

    private func matchesSearch(_ subscription: Subscription) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return subscription.name.localizedCaseInsensitiveContains(query)
    }

    private func sortComparator(_ lhs: Subscription, _ rhs: Subscription) -> Bool {
        switch sortOption {
        case .nextBilling:     lhs.nextBillingDate < rhs.nextBillingDate
        case .priceDescending: lhs.monthlyEquivalent > rhs.monthlyEquivalent
        case .nameAscending:   lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
