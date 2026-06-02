//
//  SubscriptionService.swift
//  SubTrack
//
//  Couche métier : isole toute manipulation de la persistance (CRUD) et les
//  agrégats financiers. Les Views et ViewModels dépendent du protocole
//  `SubscriptionServicing` (inversion de dépendance, SOLID-D) et non de
//  l'implémentation SwiftData concrète.
//

import Foundation
import SwiftData

// MARK: - Protocole (CRUD uniquement — les agrégats vivent dans SubscriptionMetrics)

@MainActor
protocol SubscriptionServicing {
    /// Persiste un nouvel abonnement.
    func add(_ subscription: Subscription) throws
    /// Sauvegarde les modifications d'un abonnement existant (met à jour `updatedAt`).
    func update(_ subscription: Subscription) throws
    /// Supprime définitivement un abonnement.
    func delete(_ subscription: Subscription) throws
    /// Bascule l'état actif / en pause.
    func toggleActive(_ subscription: Subscription) throws
}

// MARK: - Implémentation SwiftData

@MainActor
final class SubscriptionService: SubscriptionServicing {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ subscription: Subscription) throws {
        context.insert(subscription)
        try context.save()
    }

    func update(_ subscription: Subscription) throws {
        subscription.updatedAt = .now
        try context.save()
    }

    func delete(_ subscription: Subscription) throws {
        context.delete(subscription)
        try context.save()
    }

    func toggleActive(_ subscription: Subscription) throws {
        subscription.isActive.toggle()
        subscription.updatedAt = .now
        try context.save()
    }
}
