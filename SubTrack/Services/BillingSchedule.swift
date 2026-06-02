//
//  BillingSchedule.swift
//  SubTrack
//
//  Projette les prélèvements d'un abonnement sur un intervalle de dates
//  (utilisé par la vue calendrier). Calcul pur, testable, sans état.
//

import Foundation

enum BillingSchedule {

    /// Toutes les occurrences de prélèvement d'un abonnement comprises dans
    /// `interval`, dérivées de `nextBillingDate` en remontant/avançant d'un cycle.
    static func occurrences(of subscription: Subscription, in interval: DateInterval) -> [Date] {
        let calendar = Calendar.current
        let (component, value) = subscription.billingCycle.dateComponent
        var date = calendar.startOfDay(for: subscription.nextBillingDate)

        // Recule jusqu'à passer avant le début de l'intervalle.
        var safety = 0
        while date > interval.start && safety < 600 {
            guard let previous = calendar.date(byAdding: component, value: -value, to: date) else { break }
            date = previous
            safety += 1
        }

        // Avance en collectant les occurrences dans l'intervalle.
        var result: [Date] = []
        safety = 0
        while date <= interval.end && safety < 600 {
            if date >= interval.start { result.append(date) }
            guard let next = calendar.date(byAdding: component, value: value, to: date) else { break }
            date = next
            safety += 1
        }
        return result
    }

    /// Regroupe les abonnements actifs par jour de prélèvement sur l'intervalle.
    /// - Returns: dictionnaire `[jour normalisé: abonnements]`.
    static func occurrencesByDay(_ subscriptions: [Subscription], in interval: DateInterval) -> [Date: [Subscription]] {
        let calendar = Calendar.current
        var map: [Date: [Subscription]] = [:]
        for subscription in subscriptions where subscription.isActive {
            for date in occurrences(of: subscription, in: interval) {
                let day = calendar.startOfDay(for: date)
                map[day, default: []].append(subscription)
            }
        }
        return map
    }
}
