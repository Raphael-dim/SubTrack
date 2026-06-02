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

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                notificationsSection
                aboutSection
                #if DEBUG
                developerSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle("Réglages")
        }
    }

    // MARK: Apparence

    private var appearanceSection: some View {
        Section("Apparence") {
            Picker(selection: appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.symbolName).tag(mode)
                }
            } label: {
                Label("Thème", systemImage: "paintpalette.fill")
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label("Rappels de prélèvement", systemImage: "bell.badge.fill")
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
                    Label("Me prévenir", systemImage: "clock.fill")
                }
                .onChange(of: reminderLeadDays) { _, _ in
                    Task { await NotificationScheduler.reschedule(for: subscriptions) }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Rappels 100 % locaux, avant chaque prélèvement et chaque fin d'essai. Aucune donnée n'est envoyée.")
        }
    }

    private func leadLabel(_ days: Int) -> String {
        switch days {
        case 0: "Le jour même"
        case 1: "1 jour avant"
        default: "\(days) jours avant"
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
            LabeledContent("Abonnements", value: "\(subscriptions.count)")
            LabeledContent("Version", value: appVersion)
            Label("100 % local — aucune donnée ne quitte votre appareil.", systemImage: "lock.shield.fill")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.textSecondary)
        } header: {
            Text("À propos")
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
                Label("Seed au démarrage", systemImage: "shippingbox.fill")
            }

            Button {
                reseed()
            } label: {
                Label("Recharger le catalogue de démo", systemImage: "arrow.clockwise")
            }

            Button(role: .destructive) {
                clearAll()
            } label: {
                Label("Tout effacer", systemImage: "trash")
            }
        } header: {
            Text("Développeur")
        } footer: {
            Text("Section visible uniquement en build de développement (DEBUG).")
        }
    }

    private func reseed() {
        clearAll(playHaptic: false)
        try? SeedDataProvider.seedIfNeeded(in: context)
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
