//
//  NotificationScheduler.swift
//  SubTrack
//
//  Rappels 100% locaux (UserNotifications) — aucune infrastructure push, rien
//  ne quitte l'appareil. Planifie un rappel avant chaque prochain prélèvement
//  et avant chaque fin d'essai gratuit, selon les réglages de l'utilisateur.
//

import Foundation
import UserNotifications

enum NotificationScheduler {

    /// Demande l'autorisation d'envoyer des notifications.
    /// - Returns: `true` si accordée.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Reprogramme tous les rappels à partir de l'état courant des abonnements
    /// et des préférences (lit `UserDefaults` pour rester appelable de partout).
    /// Idempotent : purge d'abord tous les rappels en attente.
    /// `@MainActor` car `Subscription` (modèle SwiftData) n'est pas `Sendable`.
    @MainActor
    static func reschedule(for subscriptions: [Subscription]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: PreferenceKey.notificationsEnabled) else { return }

        // Autorisation effective ?
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let leadDays = max(0, defaults.integer(forKey: PreferenceKey.reminderLeadDays))

        for subscription in subscriptions where subscription.isActive && subscription.notificationsEnabled {
            scheduleBillingReminder(for: subscription, leadDays: leadDays, on: center)
            scheduleTrialReminder(for: subscription, leadDays: leadDays, on: center)
        }
    }

    // MARK: Programmation unitaire

    private static func scheduleBillingReminder(for subscription: Subscription, leadDays: Int, on center: UNUserNotificationCenter) {
        guard let fireDate = fireDate(before: subscription.nextBillingDate, leadDays: leadDays) else { return }

        let content = UNMutableNotificationContent()
        content.title = L.t("Prélèvement à venir")
        let price = subscription.effectivePrice.currencyFormatted()
        content.body = L.t("%@ — %@ le %@", subscription.name, price, subscription.nextBillingDate.appFormattedDate())
        content.sound = .default

        add(content, at: fireDate, id: "\(subscription.id.uuidString)-billing", on: center)
    }

    private static func scheduleTrialReminder(for subscription: Subscription, leadDays: Int, on center: UNUserNotificationCenter) {
        guard let trialEnd = subscription.trialEndDate, subscription.isInTrial,
              let fireDate = fireDate(before: trialEnd, leadDays: leadDays) else { return }

        let content = UNMutableNotificationContent()
        content.title = L.t("Fin d'essai gratuit")
        content.body = L.t("%@ : l'essai se termine le %@. Pensez à résilier si besoin.", subscription.name, trialEnd.appFormattedDate())
        content.sound = .default

        add(content, at: fireDate, id: "\(subscription.id.uuidString)-trial", on: center)
    }

    // MARK: Helpers

    /// Date de déclenchement (à 9 h) `leadDays` avant l'échéance, ou `nil` si
    /// cette date est déjà passée.
    private static func fireDate(before dueDate: Date, leadDays: Int) -> DateComponents? {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: .day, value: -leadDays, to: dueDate) else { return nil }
        var components = calendar.dateComponents([.year, .month, .day], from: target)
        components.hour = 9
        guard let fire = calendar.date(from: components), fire > .now else { return nil }
        return components
    }

    private static func add(_ content: UNMutableNotificationContent, at components: DateComponents, id: String, on center: UNUserNotificationCenter) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
