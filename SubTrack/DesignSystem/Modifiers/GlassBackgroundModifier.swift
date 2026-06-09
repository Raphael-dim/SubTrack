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
    /// Teinte optionnelle lavée dans le verre (cartes héros). `nil` = neutre.
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)
                    if let tint {
                        // Lavis coloré très léger, plus présent en haut à gauche.
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.16), tint.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
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
                // Rim de verre : liseré plus lumineux en haut, qui s'éteint en bas.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Theme.Palette.glassEdgeTop, Theme.Palette.glassEdgeBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: Theme.Size.hairline
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Theme.Palette.cardShadow, radius: 16, x: 0, y: 8)
    }
}

extension View {

    /// Applique le fond « Liquid Glass » standard de SubTrack.
    /// - Parameters:
    ///   - cornerRadius: rayon des coins (défaut : carte).
    ///   - material: épaisseur du flou (défaut : `.regularMaterial`).
    ///   - tint: teinte lavée dans le verre (défaut : aucune).
    func glassBackground(
        cornerRadius: CGFloat = Theme.Radius.card,
        material: Material = .regularMaterial,
        tint: Color? = nil
    ) -> some View {
        modifier(GlassBackgroundModifier(cornerRadius: cornerRadius, material: material, tint: tint))
    }
}
