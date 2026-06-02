//
//  HapticEnvironment.swift
//  SubTrack
//
//  Injecte le fournisseur haptique dans l'environnement SwiftUI (DI propre).
//  Les Views appellent `@Environment(\.haptics)` plutôt que d'instancier un
//  générateur — substituable par un mock dans les previews.
//

import SwiftUI

private struct HapticsEnvironmentKey: EnvironmentKey {
    /// Défaut no-op (non isolé) ; le vrai `HapticsManager` est injecté à la
    /// racine de l'app via `.environment(\.haptics, .shared)`.
    static let defaultValue: any HapticsProviding = NoopHapticsManager()
}

extension EnvironmentValues {
    var haptics: HapticsProviding {
        get { self[HapticsEnvironmentKey.self] }
        set { self[HapticsEnvironmentKey.self] = newValue }
    }
}

extension View {

    /// Déclenche un retour haptique à chaque changement de `trigger`.
    /// Sucre syntaxique au-dessus de `sensoryFeedback`, mappé sur nos types.
    func hapticFeedback<T: Equatable>(_ feedback: HapticFeedback, trigger: T) -> some View {
        sensoryFeedback(trigger: trigger) { _, _ in feedback.sensoryFeedback }
    }
}

private extension HapticFeedback {
    /// Conversion vers le type natif SwiftUI `SensoryFeedback`.
    var sensoryFeedback: SensoryFeedback {
        switch self {
        case .light:     .impact(weight: .light)
        case .medium:    .impact(weight: .medium)
        case .success:   .success
        case .warning:   .warning
        case .error:     .error
        case .selection: .selection
        }
    }
}
