//
//  AppearanceMode.swift
//  SubTrack
//
//  Préférence de thème choisie par l'utilisateur, persistée via @AppStorage.
//  `nil` colorScheme = on suit le réglage système.
//

import SwiftUI

/// Clés de préférences (centralisées pour éviter les chaînes magiques).
enum PreferenceKey {
    static let appearanceMode = "appearanceMode"
    /// DEBUG uniquement : autorise le seed du catalogue de démo au démarrage.
    static let devSeedEnabled = "devSeedEnabled"
    /// Rappels locaux activés globalement.
    static let notificationsEnabled = "notificationsEnabled"
    /// Nombre de jours avant l'échéance pour déclencher le rappel.
    static let reminderLeadDays = "reminderLeadDays"
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Système"
        case .light:  "Clair"
        case .dark:   "Sombre"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max.fill"
        case .dark:   "moon.fill"
        }
    }

    /// `nil` → laisse SwiftUI suivre l'apparence du système.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}
