//
//  SubTrackApp.swift
//  SubTrack
//
//  Point d'entrée de l'application. Configure le `ModelContainer` SwiftData
//  (stockage 100% local, aucune option CloudKit) et amorce le catalogue au
//  premier lancement.
//

import SwiftUI
import SwiftData

@main
struct SubTrackApp: App {

    /// Conteneur SwiftData partagé. Persistance locale sur disque.
    let modelContainer: ModelContainer

    init() {
        // Valeurs par défaut des préférences avant toute lecture.
        UserDefaults.standard.register(defaults: [
            PreferenceKey.devSeedEnabled: true,
            PreferenceKey.reminderLeadDays: 2,
            PreferenceKey.appLanguage: AppLanguage.system.rawValue,
            PreferenceKey.currencyCode: AppCurrency.eur.rawValue
        ])

        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // confidentialité absolue : pas de sync iCloud
        )

        modelContainer = Self.makeContainer(configuration)
        Self.bootstrapSeed(in: modelContainer.mainContext)
    }

    /// Ouvre le conteneur en tolérant un store incompatible : si le schéma a
    /// changé (ajout de champs en développement), on réinitialise la base
    /// locale plutôt que de crasher. Données 100 % locales et re-seedées.
    private static func makeContainer(_ configuration: ModelConfiguration) -> ModelContainer {
        do {
            return try ModelContainer(for: Subscription.self, configurations: configuration)
        } catch {
            print("SubTrack · store incompatible (\(error)). Réinitialisation…")
            destroyStore(at: configuration.url)
            do {
                return try ModelContainer(for: Subscription.self, configurations: configuration)
            } catch {
                // Dernier recours : base en mémoire pour ne jamais bloquer le lancement.
                print("SubTrack · repli en mémoire : \(error)")
                let memory = ModelConfiguration(isStoredInMemoryOnly: true)
                return try! ModelContainer(for: Subscription.self, configurations: memory)
            }
        }
    }

    /// Supprime le fichier de store SwiftData et ses annexes (-wal / -shm).
    private static func destroyStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.haptics, HapticsManager.shared)
        }
        .modelContainer(modelContainer)
    }

    /// Amorce le catalogue une seule fois (idempotent côté provider).
    @MainActor
    private static func bootstrapSeed(in context: ModelContext) {
        #if DEBUG
        // En développement, le seed peut être désactivé depuis les Réglages.
        guard UserDefaults.standard.bool(forKey: PreferenceKey.devSeedEnabled) else {
            print("SubTrack · seed désactivé (Réglages › Développeur).")
            return
        }
        #endif
        do {
            let inserted = try SeedDataProvider.seedIfNeeded(in: context)
            if inserted > 0 {
                print("SubTrack · seed : \(inserted) abonnements insérés.")
            }
        } catch {
            print("SubTrack · échec du seed : \(error)")
        }
    }
}
