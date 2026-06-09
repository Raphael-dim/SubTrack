//
//  Theme.swift
//  SubTrack
//
//  Source unique de vérité du système de design (DRY). Aucune valeur magique
//  (spacing, rayon, couleur) ne doit être codée en dur dans les Views : tout
//  passe par ces tokens. Les couleurs sont adaptatives Dark/Light via des
//  `UIColor` dynamiques, sans dépendre d'un Asset Catalog.
//

import SwiftUI

enum Theme {

    // MARK: Espacements (grille 4 pt)

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Rayons de coin (style `.continuous` partout)

    enum Radius {
        static let pill: CGFloat = 999
        static let chip: CGFloat = 12
        static let card: CGFloat = 24
        static let sheet: CGFloat = 32
        static let icon: CGFloat = 14
    }

    // MARK: Dimensions récurrentes

    enum Size {
        /// Côté de la pastille d'icône d'un abonnement.
        static let iconBadge: CGFloat = 44
        /// Cible tactile minimale (HIG).
        static let minTouchTarget: CGFloat = 44
        /// Épaisseur de la bordure « verre ».
        static let hairline: CGFloat = 1
    }

    // MARK: Palette adaptative

    enum Palette {
        /// Couleur de marque de l'app (indigo).
        static let appAccent = dynamic(light: 0x5E5CE6, dark: 0x7D7AFF)

        /// Fond d'écran principal (sous le verre).
        static let background = dynamic(light: 0xF5F5F7, dark: 0x0A0A0C)

        /// Halo ambiant principal du fond (indigo, en haut).
        static let backgroundGlowPrimary = dynamic(
            light: 0x5E5CE6, lightAlpha: 0.09,
            dark: 0x7D7AFF, darkAlpha: 0.13
        )

        /// Halo ambiant secondaire du fond (cyan, en bas à droite).
        static let backgroundGlowSecondary = dynamic(
            light: 0x32ADE6, lightAlpha: 0.06,
            dark: 0x5AC8FA, darkAlpha: 0.07
        )

        /// Texte primaire (titres, montants).
        static let textPrimary = dynamic(light: 0x0A0A0C, dark: 0xF5F5F7)

        /// Texte secondaire (métadonnées).
        static let textSecondary = dynamic(light: 0x6E6E73, dark: 0x98989D)

        /// Séparateurs et liserés fins (visibles dans les deux modes).
        static let glassBorder = dynamic(
            light: 0x000000, lightAlpha: 0.06,
            dark: 0xFFFFFF, darkAlpha: 0.10
        )

        /// Haut du liseré « rim de verre » des cartes (plus lumineux).
        static let glassEdgeTop = dynamic(
            light: 0xFFFFFF, lightAlpha: 0.60,
            dark: 0xFFFFFF, darkAlpha: 0.22
        )

        /// Bas du liseré « rim de verre » des cartes (s'éteint).
        static let glassEdgeBottom = dynamic(
            light: 0xFFFFFF, lightAlpha: 0.12,
            dark: 0xFFFFFF, darkAlpha: 0.04
        )

        /// Reflet supérieur discret des cartes.
        static let glassHighlight = dynamic(
            light: 0xFFFFFF, lightAlpha: 0.30,
            dark: 0xFFFFFF, darkAlpha: 0.07
        )

        /// Ombre portée des cartes (douce en clair, plus présente en sombre).
        static let cardShadow = dynamic(
            light: 0x000000, lightAlpha: 0.08,
            dark: 0x000000, darkAlpha: 0.32
        )
    }

    // MARK: Helpers

    /// Crée une `Color` qui s'adapte automatiquement au mode clair/sombre.
    private static func dynamic(
        light: UInt64, lightAlpha: CGFloat = 1,
        dark: UInt64, darkAlpha: CGFloat = 1
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let hex = isDark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        })
    }
}
