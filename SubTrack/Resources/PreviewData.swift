//
//  PreviewData.swift
//  SubTrack
//
//  Conteneur SwiftData en mémoire, pré-rempli avec le catalogue de seed, à
//  l'usage exclusif des #Preview Xcode. Aucune donnée n'est écrite sur disque.
//

import SwiftData

enum PreviewData {

    /// Conteneur in-memory seedé, partagé par les previews.
    @MainActor static let container: ModelContainer = {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Subscription.self, configurations: configuration)
            SeedDataProvider.makeCatalog().forEach(container.mainContext.insert)
            return container
        } catch {
            fatalError("Échec du conteneur de preview : \(error)")
        }
    }()
}
