//
//  Subscription.swift
//  SubTrack
//
//  Entité persistée centrale. 100% local via SwiftData — aucune donnée ne
//  quitte l'appareil. Les montants sont des `Decimal` (précision monétaire),
//  les couleurs et les énumérations sont stockées sous une forme stable.
//

import Foundation
import SwiftData

@Model
final class Subscription {

    /// Identité stable, indépendante de l'`PersistentIdentifier` SwiftData.
    /// Utile pour les transitions (`matchedGeometryEffect`) et les tests.
    @Attribute(.unique) var id: UUID

    var name: String
    var price: Decimal
    var currencyCode: String

    /// Périodicité de facturation. Enum `Codable` persisté tel quel.
    var billingCycle: BillingCycle

    /// Catégorie de l'abonnement. Enum `Codable` persisté tel quel.
    var category: SubscriptionCategory

    /// Date du prochain prélèvement.
    var nextBillingDate: Date

    /// Date de souscription initiale.
    var startDate: Date

    /// Couleur de marque de l'abonnement (ex. rouge Netflix), en hexadécimal.
    var accentColorHex: String

    /// Domaine de la marque (ex. `"netflix.com"`), utilisé pour récupérer le
    /// logo à distance (voir `BrandLogo`). `nil` → on retombe sur le monogramme
    /// ou `iconSystemName`. Aucun logo n'est embarqué dans le bundle.
    var brandDomain: String?

    /// SF Symbol affiché si aucun logo de marque n'est disponible.
    var iconSystemName: String

    var notes: String?

    /// Permet de mettre un abonnement « en pause » sans le supprimer.
    var isActive: Bool

    // MARK: Essai gratuit & remise

    /// Si défini et postérieur à maintenant : l'abonnement est en essai gratuit
    /// (coût effectif = 0) jusqu'à cette date.
    var trialEndDate: Date?

    /// Prix promotionnel temporaire. `nil` → pas de promo.
    var promoPrice: Decimal?

    /// Fin de la promo. `nil` avec `promoPrice` non nil → promo sans échéance.
    var promoEndDate: Date?

    // MARK: Notifications

    /// Rappels locaux activés pour cet abonnement (réglage global mis à part).
    /// Valeur par défaut inline → migration légère SwiftData sans réinitialisation.
    var notificationsEnabled: Bool = true

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        currencyCode: String = "EUR",
        billingCycle: BillingCycle,
        category: SubscriptionCategory,
        nextBillingDate: Date,
        startDate: Date = .now,
        accentColorHex: String,
        brandDomain: String? = nil,
        iconSystemName: String,
        notes: String? = nil,
        isActive: Bool = true,
        trialEndDate: Date? = nil,
        promoPrice: Decimal? = nil,
        promoEndDate: Date? = nil,
        notificationsEnabled: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.category = category
        self.nextBillingDate = nextBillingDate
        self.startDate = startDate
        self.accentColorHex = accentColorHex
        self.brandDomain = brandDomain
        self.iconSystemName = iconSystemName
        self.notes = notes
        self.isActive = isActive
        self.trialEndDate = trialEndDate
        self.promoPrice = promoPrice
        self.promoEndDate = promoEndDate
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Propriétés calculées (non persistées)

extension Subscription {

    /// `true` si l'essai gratuit est en cours (coût effectif nul actuellement).
    var isInTrial: Bool {
        guard let trialEndDate else { return false }
        return trialEndDate > .now
    }

    /// `true` si une promo est active (sans échéance, ou échéance future).
    var isPromoActive: Bool {
        guard promoPrice != nil else { return false }
        guard let promoEndDate else { return true }
        return promoEndDate > .now
    }

    /// Prix réellement facturé aujourd'hui : 0 en essai, prix promo si actif,
    /// sinon prix normal. Base de tous les totaux (dépense réelle courante).
    var effectivePrice: Decimal {
        if isInTrial { return 0 }
        if isPromoActive, let promoPrice { return promoPrice }
        return price
    }

    /// Coût ramené au mois, quelle que soit la périodicité.
    /// Base unique pour le total mensuel et les statistiques (DRY).
    var monthlyEquivalent: Decimal {
        yearlyEquivalent / 12
    }

    /// Coût annualisé (prix effectif × nombre d'occurrences par an).
    var yearlyEquivalent: Decimal {
        effectivePrice * billingCycle.occurrencesPerYear
    }

    /// Nombre de jours avant la fin de l'essai (nil si pas d'essai en cours).
    var daysUntilTrialEnds: Int? {
        guard let trialEndDate, isInTrial else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: trialEndDate)).day
    }

    /// Nombre de jours (calendaires) avant le prochain prélèvement.
    /// Négatif si la date est dépassée (prélèvement en retard de mise à jour).
    var daysUntilNextBilling: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: nextBillingDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }
}
