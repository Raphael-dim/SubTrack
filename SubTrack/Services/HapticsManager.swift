//
//  HapticsManager.swift
//  SubTrack
//
//  Wrapper haptique réutilisable. Abstrait derrière un protocole pour
//  l'injection de dépendances et la testabilité (on peut substituer un
//  mock silencieux dans les tests / previews).
//

import UIKit

/// Types de retours haptiques exposés à l'app, indépendants de l'API UIKit.
enum HapticFeedback {
    case light
    case medium
    case success
    case warning
    case error
    case selection
}

@MainActor
protocol HapticsProviding: Sendable {
    func play(_ feedback: HapticFeedback)
}

/// Implémentation par défaut s'appuyant sur les générateurs UIKit.
/// `@MainActor` car les générateurs haptiques doivent être pilotés sur le thread principal.
@MainActor
final class HapticsManager: HapticsProviding {

    static let shared = HapticsManager()

    init() {}

    func play(_ feedback: HapticFeedback) {
        switch feedback {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

/// Mock no-op pour previews et tests unitaires.
@MainActor
final class NoopHapticsManager: HapticsProviding {
    /// `init` non isolé pour pouvoir servir de valeur par défaut d'environnement
    /// (contexte non-isolé) sans franchir la frontière d'acteur.
    nonisolated init() {}
    func play(_ feedback: HapticFeedback) {}
}
