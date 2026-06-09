//
//  GlassCard.swift
//  SubTrack
//
//  Conteneur générique « Liquid Glass ». Brique de composition de toute
//  l'interface : on enveloppe n'importe quel contenu sans réécrire les
//  réglages de matériau, padding et ombre (DRY + KISS).
//

import SwiftUI
import UIKit

struct GlassCard<Content: View>: View {

    var cornerRadius: CGFloat
    var padding: CGFloat
    /// Teinte lavée dans le verre (cartes héros). `nil` = carte neutre.
    var tint: Color?
    @ViewBuilder var content: Content

    init(
        cornerRadius: CGFloat = Theme.Radius.card,
        padding: CGFloat = Theme.Spacing.md,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBackground(cornerRadius: cornerRadius, tint: tint)
    }
}

// MARK: - Pastille d'icône colorée

/// Pastille d'abonnement. Quand un `domain` de marque est fourni, télécharge le
/// vrai logo (Logo.dev → favicon, voir `BrandLogo`) et l'affiche sur une tuile
/// claire ; en attendant ou en cas d'échec, retombe sur un monogramme teinté.
/// Sans domaine, affiche le SF Symbol fourni. Réutilisée dans la liste, le
/// détail, les stats et l'éditeur.
struct IconBadge: View {

    let systemName: String
    let tint: Color
    /// Nom de la marque, source du monogramme de repli (ex. « Netflix » → "N").
    var brandName: String = ""
    /// Domaine de la marque (ex. "netflix.com"). `nil`/vide → SF Symbol.
    var domain: String? = nil
    var size: CGFloat = Theme.Size.iconBadge

    @State private var logo: UIImage?

    private var hasBrand: Bool { !(domain ?? "").isEmpty }

    var body: some View {
        content
            .accessibilityHidden(true)
            .task(id: domain) { await loadLogo() }
    }

    @ViewBuilder private var content: some View {
        if let logo {
            logoBadge(logo)
        } else if hasBrand {
            monogramBadge          // placeholder pendant le chargement & repli
        } else {
            symbolBadge
        }
    }

    /// Essaie les URLs candidates dans l'ordre ; s'arrête à la première image
    /// valide. Sans domaine, ne fait rien (le SF Symbol est affiché).
    private func loadLogo() async {
        logo = nil
        guard let domain, !domain.isEmpty else { return }
        for url in BrandLogo.candidateURLs(domain: domain, pointSize: size) {
            if let image = await BrandLogoFetcher.fetch(url) {
                logo = image
                return
            }
        }
    }

    private func logoBadge(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .padding(size * 0.18)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous)
                    .fill(.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous)
                    .strokeBorder(Theme.Palette.glassBorder, lineWidth: Theme.Size.hairline)
            }
    }

    private var monogramBadge: some View {
        tintedTile {
            Text(brandName.monogram)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    private var symbolBadge: some View {
        tintedTile {
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(tint)
        }
    }

    /// Tuile teintée commune au monogramme et au SF Symbol (DRY).
    private func tintedTile<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        inner()
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous)
                    .fill(tint.opacity(0.16))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: Theme.Size.hairline)
            }
    }
}

// MARK: - Previews

#Preview("GlassCard – Dark") {
    ZStack {
        AppBackground()
        VStack(spacing: Theme.Spacing.md) {
            GlassCard {
                HStack(spacing: Theme.Spacing.sm) {
                    IconBadge(systemName: "play.rectangle.fill", tint: Color(hex: "#E50914"))
                    VStack(alignment: .leading) {
                        Text("Netflix").font(.headline)
                        Text("13,49 € · Mensuel")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    Spacer()
                }
            }
            GlassCard {
                Text("Total mensuel")
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
