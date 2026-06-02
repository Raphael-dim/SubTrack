//
//  SeedDataProvider.swift
//  SubTrack
//
//  Catalogue d'amorçage : >20 abonnements réalistes pré-configurés, insérés
//  au tout premier lancement pour que l'utilisateur ne parte pas d'un écran
//  vide. 100% local, aucune requête réseau.
//
//  Les dates de prochain prélèvement sont calculées dynamiquement à partir
//  de « maintenant » (décalage en jours), afin que le seed reste pertinent
//  quelle que soit la date d'installation.
//

import Foundation
import SwiftData

enum SeedDataProvider {

    /// Insère le catalogue uniquement si la base est vide (idempotent).
    /// À appeler une fois au démarrage de l'app.
    /// - Returns: le nombre d'abonnements insérés (0 si la base était déjà peuplée).
    @discardableResult
    static func seedIfNeeded(in context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<Subscription>()
        descriptor.fetchLimit = 1
        let isEmpty = try context.fetch(descriptor).isEmpty
        guard isEmpty else { return 0 }

        let subscriptions = makeCatalog()
        subscriptions.forEach(context.insert)
        try context.save()
        return subscriptions.count
    }

    /// Construit les abonnements de démo à partir du `ServiceCatalog` (source
    /// unique). Les dates de prélèvement sont réparties sur ~4 semaines pour
    /// donner une liste vivante, quelle que soit la date d'installation.
    static func makeCatalog() -> [Subscription] {
        ServiceCatalog.all.enumerated().map { index, template in
            let subscription = Subscription(
                name: template.name,
                price: template.suggestedPrice,
                billingCycle: template.billingCycle,
                category: template.category,
                nextBillingDate: inDays((index * 3) % 27 + 1),
                accentColorHex: template.accentColorHex,
                brandDomain: template.brandDomain,
                iconSystemName: template.iconSystemName
            )
            // Quelques essais / promos en démo (pour illustrer la fonctionnalité).
            switch template.name {
            case "Disney+", "ChatGPT Plus":
                subscription.trialEndDate = inDays(template.name == "Disney+" ? 7 : 21)
            case "Spotify Premium":
                subscription.promoPrice = 5.99
                subscription.promoEndDate = inDays(60)
            case "Adobe Creative Cloud":
                subscription.promoPrice = 39.99 // sans échéance
            default:
                break
            }
            return subscription
        }
    }

    // MARK: - Helpers

    /// Date à `days` jours de maintenant, normalisée au début de journée.
    private static func inDays(_ days: Int) -> Date {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .day, value: days, to: base) ?? base
    }
}
