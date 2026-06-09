//
//  AppBackground.swift
//  SubTrack
//
//  Fond d'écran commun à tous les écrans : couleur de base + deux halos
//  radiaux très discrets (indigo en haut, cyan en bas à droite) qui donnent
//  de la profondeur sans attirer l'œil. Adaptatif Dark/Light via les tokens
//  du Theme, statique (aucun coût d'animation).
//

import SwiftUI

struct AppBackground: View {

    var body: some View {
        ZStack {
            Theme.Palette.background

            RadialGradient(
                colors: [Theme.Palette.backgroundGlowPrimary, .clear],
                center: UnitPoint(x: 0.12, y: -0.05),
                startRadius: 0,
                endRadius: 440
            )

            RadialGradient(
                colors: [Theme.Palette.backgroundGlowSecondary, .clear],
                center: UnitPoint(x: 1.05, y: 0.42),
                startRadius: 0,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

extension View {

    /// Applique le fond ambiant standard de SubTrack derrière la vue.
    func appBackground() -> some View {
        background { AppBackground() }
    }
}

#Preview("AppBackground – Dark") {
    AppBackground().preferredColorScheme(.dark)
}

#Preview("AppBackground – Light") {
    AppBackground().preferredColorScheme(.light)
}
