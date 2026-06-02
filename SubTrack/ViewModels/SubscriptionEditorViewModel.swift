//
//  SubscriptionEditorViewModel.swift
//  SubTrack
//
//  Pilote le formulaire unifié d'ajout ET d'édition (DRY : une seule vue, un
//  seul VM). Gère les champs de saisie, la validation, et la persistance via
//  le service. Le mode (création vs édition) est déterminé par la présence
//  d'un abonnement existant.
//

import Foundation
import Observation

@Observable
@MainActor
final class SubscriptionEditorViewModel {

    enum Mode {
        case create
        case edit(Subscription)
    }

    // MARK: Champs du formulaire

    var name: String
    var priceText: String
    var billingCycle: BillingCycle
    var category: SubscriptionCategory
    var nextBillingDate: Date
    var startDate: Date
    var accentColorHex: String
    /// Domaine de marque (pour le logo distant) conservé tel quel ; remis à
    /// `nil` dès que l'utilisateur choisit un SF Symbol dans la grille.
    var brandDomain: String?
    var iconSystemName: String
    var notes: String
    var isActive: Bool

    // Essai gratuit
    var hasTrial: Bool
    var trialEndDate: Date

    // Remise / promo
    var hasPromo: Bool
    var promoPriceText: String
    var hasPromoEnd: Bool
    var promoEndDate: Date

    // Notifications (par abonnement)
    var notificationsEnabled: Bool

    // MARK: Dépendances / état

    private let mode: Mode
    private let service: SubscriptionServicing

    var navigationTitle: String {
        switch mode {
        case .create: "Nouvel abonnement"
        case .edit:   "Modifier"
        }
    }

    /// `true` en mode édition (sert à afficher la section Statut).
    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(mode: Mode, service: SubscriptionServicing) {
        self.mode = mode
        self.service = service

        let inOneMonth = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
        let inThreeMonths = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now

        switch mode {
        case .create:
            name = ""
            priceText = ""
            billingCycle = .monthly
            category = .entertainment
            nextBillingDate = inOneMonth
            startDate = .now
            accentColorHex = SubscriptionCategory.entertainment.accentColorHex
            brandDomain = nil
            iconSystemName = "creditcard.fill"
            notes = ""
            isActive = true
            hasTrial = false
            trialEndDate = inOneMonth
            hasPromo = false
            promoPriceText = ""
            hasPromoEnd = false
            promoEndDate = inThreeMonths
            notificationsEnabled = true

        case .edit(let subscription):
            name = subscription.name
            priceText = Self.priceFormatter.string(from: subscription.price as NSDecimalNumber) ?? ""
            billingCycle = subscription.billingCycle
            category = subscription.category
            nextBillingDate = subscription.nextBillingDate
            startDate = subscription.startDate
            accentColorHex = subscription.accentColorHex
            brandDomain = subscription.brandDomain
            iconSystemName = subscription.iconSystemName
            notes = subscription.notes ?? ""
            isActive = subscription.isActive
            hasTrial = subscription.trialEndDate != nil
            trialEndDate = subscription.trialEndDate ?? inOneMonth
            hasPromo = subscription.promoPrice != nil
            promoPriceText = subscription.promoPrice.map { Self.priceFormatter.string(from: $0 as NSDecimalNumber) ?? "" } ?? ""
            hasPromoEnd = subscription.promoEndDate != nil
            promoEndDate = subscription.promoEndDate ?? inThreeMonths
            notificationsEnabled = subscription.notificationsEnabled
        }
    }

    // MARK: Autocomplétion

    /// Pré-remplit le formulaire à partir d'un service connu choisi dans les
    /// suggestions (nom, prix indicatif, périodicité, catégorie, couleur, logo).
    func apply(template: ServiceTemplate) {
        name = template.name
        priceText = Self.priceFormatter.string(from: template.suggestedPrice as NSDecimalNumber) ?? ""
        billingCycle = template.billingCycle
        category = template.category
        accentColorHex = template.accentColorHex
        brandDomain = template.brandDomain
        iconSystemName = template.iconSystemName
    }

    /// Suggestions de services connus correspondant au nom en cours de saisie.
    var suggestions: [ServiceTemplate] {
        ServiceCatalog.matching(name)
    }

    // MARK: Validation

    /// Prix saisi converti en `Decimal`, ou `nil` si invalide.
    var parsedPrice: Decimal? {
        let normalized = priceText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: normalized), value >= 0 else { return nil }
        return value
    }

    /// Prix promo saisi (ou `nil` si invalide / vide).
    var parsedPromoPrice: Decimal? {
        let normalized = promoPriceText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: normalized), value >= 0 else { return nil }
        return value
    }

    /// Valeurs essai/promo résolues à partir des toggles.
    private var resolvedTrialEnd: Date? { hasTrial ? trialEndDate : nil }
    private var resolvedPromoPrice: Decimal? { hasPromo ? parsedPromoPrice : nil }
    private var resolvedPromoEnd: Date? { (hasPromo && hasPromoEnd) ? promoEndDate : nil }

    /// `true` si le formulaire peut être enregistré.
    var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, parsedPrice != nil else { return false }
        if hasPromo && parsedPromoPrice == nil { return false } // promo activée mais prix invalide
        return true
    }

    // MARK: Persistance

    /// Crée ou met à jour l'abonnement. À n'appeler que si `canSave == true`.
    func save() throws {
        guard let price = parsedPrice else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            let subscription = Subscription(
                name: trimmedName,
                price: price,
                billingCycle: billingCycle,
                category: category,
                nextBillingDate: nextBillingDate,
                startDate: startDate,
                accentColorHex: accentColorHex,
                brandDomain: brandDomain,
                iconSystemName: iconSystemName,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                isActive: isActive,
                trialEndDate: resolvedTrialEnd,
                promoPrice: resolvedPromoPrice,
                promoEndDate: resolvedPromoEnd,
                notificationsEnabled: notificationsEnabled
            )
            try service.add(subscription)

        case .edit(let subscription):
            subscription.name = trimmedName
            subscription.price = price
            subscription.billingCycle = billingCycle
            subscription.category = category
            subscription.nextBillingDate = nextBillingDate
            subscription.startDate = startDate
            subscription.accentColorHex = accentColorHex
            subscription.brandDomain = brandDomain
            subscription.iconSystemName = iconSystemName
            subscription.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            subscription.isActive = isActive
            subscription.trialEndDate = resolvedTrialEnd
            subscription.promoPrice = resolvedPromoPrice
            subscription.promoEndDate = resolvedPromoEnd
            subscription.notificationsEnabled = notificationsEnabled
            try service.update(subscription)
        }
    }

    // MARK: Formatters

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
