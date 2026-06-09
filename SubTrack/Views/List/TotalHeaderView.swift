//
//  TotalHeaderView.swift
//  SubTrack
//
//  En-tête de la liste : met en avant la dépense mensuelle (le héros), avec
//  l'équivalent annuel en secondaire. Carte « Liquid Glass » pleine largeur.
//

import SwiftUI

struct TotalHeaderView: View {

    let monthlyTotal: Decimal
    let yearlyTotal: Decimal
    let activeCount: Int

    var body: some View {
        GlassCard(padding: Theme.Spacing.lg, tint: Theme.Palette.appAccent) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(L.t("Dépense mensuelle"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Palette.textSecondary)

                Text(monthlyTotal.currencyFormatted())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Palette.textPrimary, Theme.Palette.textPrimary.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                HStack(spacing: Theme.Spacing.sm) {
                    Label(
                        L.t("%@ / an", yearlyTotal.currencyFormatted()),
                        systemImage: "calendar"
                    )
                    Label(
                        L.t("%d actifs", activeCount),
                        systemImage: "checkmark.seal.fill"
                    )
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, Theme.Spacing.xxs)
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        TotalHeaderView(monthlyTotal: 287.42, yearlyTotal: 3449.04, activeCount: 23)
            .padding()
    }
    .preferredColorScheme(.dark)
}
