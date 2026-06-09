//
//  SettingsView.swift
//  SubTrack
//
//  Réglages de l'app : apparence (thème), informations, et — uniquement en
//  build DEBUG — outils développeur pour piloter le seeder / les données.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.haptics) private var haptics

    @AppStorage(PreferenceKey.appearanceMode) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(PreferenceKey.appLanguage) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage(PreferenceKey.currencyCode) private var currencyRaw = AppCurrency.eur.rawValue
    @AppStorage(PreferenceKey.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(PreferenceKey.reminderLeadDays) private var reminderLeadDays = 2

    /// Nombre d'abonnements en base (affiché dans « À propos »).
    @Query private var subscriptions: [Subscription]

    /// Délais de rappel proposés (jours avant l'échéance).
    private let leadOptions = [0, 1, 2, 3, 7]

    private var appearance: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var language: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: languageRaw) ?? .system },
            set: { languageRaw = $0.rawValue }
        )
    }

    private var currency: Binding<AppCurrency> {
        Binding(
            get: { AppCurrency(rawValue: currencyRaw) ?? .eur },
            set: { currencyRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                preferencesSection
                notificationsSection
                aboutSection
                #if DEBUG
                developerSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle(L.t("Réglages"))
        }
    }

    // MARK: Apparence

    private var appearanceSection: some View {
        Section(L.t("Apparence")) {
            Picker(selection: appearance) {
                // Texte seul : l'icône du côté droit (valeur sélectionnée) est
                // retirée ; l'icône de gauche (label « Thème ») est conservée.
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Label(L.t("Thème"), systemImage: "paintpalette.fill")
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: Préférences (langue & devise)

    private var preferencesSection: some View {
        Section {
            Picker(selection: language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            } label: {
                Label(L.t("Langue"), systemImage: "globe")
            }
            .pickerStyle(.menu)

            Picker(selection: currency) {
                ForEach(AppCurrency.allCases) { cur in
                    Text(cur.displayName).tag(cur)
                }
            } label: {
                Label(L.t("Devise"), systemImage: "banknote.fill")
            }
            .pickerStyle(.menu)
        } header: {
            Text(L.t("Préférences"))
        } footer: {
            Text(L.t("La devise s'applique aux totaux. La langue ajuste le format des dates et des montants."))
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label(L.t("Rappels de prélèvement"), systemImage: "bell.badge.fill")
            }
            .onChange(of: notificationsEnabled) { _, enabled in
                Task { await handleNotificationsToggle(enabled) }
            }

            if notificationsEnabled {
                Picker(selection: $reminderLeadDays) {
                    ForEach(leadOptions, id: \.self) { days in
                        Text(leadLabel(days)).tag(days)
                    }
                } label: {
                    Label(L.t("Me prévenir"), systemImage: "clock.fill")
                }
                .onChange(of: reminderLeadDays) { _, _ in
                    Task { await NotificationScheduler.reschedule(for: subscriptions) }
                }
            }
        } header: {
            Text(L.t("Notifications"))
        } footer: {
            Text(L.t("Rappels 100 % locaux, avant chaque prélèvement et chaque fin d'essai. Aucune donnée n'est envoyée."))
        }
    }

    private func leadLabel(_ days: Int) -> String {
        switch days {
        case 0: L.t("Le jour même")
        case 1: L.t("1 jour avant")
        default: L.t("%d jours avant", days)
        }
    }

    /// Demande l'autorisation à l'activation ; replie le toggle si refusée.
    private func handleNotificationsToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationScheduler.requestAuthorization()
            if !granted {
                notificationsEnabled = false
                haptics.play(.error)
                return
            }
        }
        await NotificationScheduler.reschedule(for: subscriptions)
    }

    // MARK: À propos

    private var aboutSection: some View {
        Section {
            VStack(spacing: 8) {
                if let icon = Bundle.main.appIcon {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Text("SubTrack")
                    .font(.headline)
                Text(appVersion)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            LabeledContent(L.t("Abonnements"), value: "\(subscriptions.count)")
            Label(L.t("100 % local — aucune donnée ne quitte votre appareil."), systemImage: "lock.shield.fill")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.textSecondary)
        } header: {
            Text(L.t("À propos"))
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    // MARK: Développeur (DEBUG uniquement)

    #if DEBUG
    @AppStorage(PreferenceKey.devSeedEnabled) private var devSeedEnabled = true

    private var developerSection: some View {
        Section {
            Toggle(isOn: $devSeedEnabled) {
                Label(L.t("Seed au démarrage"), systemImage: "shippingbox.fill")
            }

            Button {
                reseed()
            } label: {
                Label(L.t("Recharger le catalogue de démo"), systemImage: "arrow.clockwise")
            }

            Button(role: .destructive) {
                clearAll()
            } label: {
                Label(L.t("Tout effacer"), systemImage: "trash")
            }
        } header: {
            Text(L.t("Développeur"))
        } footer: {
            Text(L.t("Section visible uniquement en build de développement (DEBUG)."))
        }
    }

    private func reseed() {
        clearAll(playHaptic: false)
        _ = try? SeedDataProvider.seedIfNeeded(in: context)
        haptics.play(.success)
    }

    private func clearAll(playHaptic: Bool = true) {
        try? context.delete(model: Subscription.self)
        try? context.save()
        if playHaptic { haptics.play(.warning) }
    }
    #endif
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
