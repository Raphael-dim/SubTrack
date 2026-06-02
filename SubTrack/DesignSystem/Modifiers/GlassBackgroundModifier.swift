//
//  GlassBackgroundModifier.swift
//  SubTrack
//
//  Modifier réutilisable matérialisant l'effet « Liquid Glass » : material
//  flouté + liseré subtil + reflet supérieur + ombre douce. Mutualisé ici
//  pour que tous les éléments en verre soient strictement cohérents (DRY).
//

import SwiftUI

struct GlassBackgroundModifier: ViewModifier {

    var cornerRadius: CGFloat = Theme.Radius.card
    var material: Material = .regularMaterial

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
            }
            .overlay {
                // Reflet supérieur discret : dégradé blanc qui s'éteint vers le bas.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Palette.glassHighlight, .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            }
            .overlay {
                // Liseré « verre » pour détacher la carte du fond.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.Palette.glassBorder, lineWidth: Theme.Size.hairline)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
}

extension View {

    /// Applique le fond « Liquid Glass » standard de SubTrack.
    /// - Parameters:
    ///   - cornerRadius: rayon des coins (défaut : carte).
    ///   - material: épaisseur du flou (défaut : `.regularMaterial`).
    func glassBackground(
        cornerRadius: CGFloat = Theme.Radius.card,
        material: Material = .regularMaterial
    ) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius, material: material))
    }
}
