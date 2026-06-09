//
//  SubscriptionRow.swift
//  SubTrack
//
//  Ligne d'un abonnement dans la liste : pastille de marque, nom, prix /
//  périodicité, et badge « prochain prélèvement ». Affichage pur (aucune
//  logique métier ici).
//

import SwiftUI

struct SubscriptionRow: View {

    let subscription: Subscription

    private var tint: Color { Color(hex: subscription.accentColorHex) }

    var body: some View {
        GlassCard(padding: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                IconBadge(
                    systemName: subscription.iconSystemName,
                    tint: tint,
                    brandName: subscription.name,
                    domain: subscription.brandDomain
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .lineLimit(1)

                    priceLine
                }

                Spacer(minLength: Theme.Spacing.xs)

                VStack(alignment: .trailing, spacing: 4) {
                    statusTag
                    billingBadge
                }
            }
            .opacity(subscription.isActive ? 1 : 0.45)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Ligne de prix (gère essai / promo)

    @ViewBuilder
    private var priceLine: some View {
        let cycle = subscription.billingCycle.displayName
        if subscription.isInTrial {
            Text(L.t("Essai gratuit · %@", cycle))
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.textSecondary)
                .lineLimit(1)
        } else if subscription.isPromoActive, let promo = subscription.promoPrice {
            HStack(spacing: 4) {
                Text(promo.currencyFormatted())
                Text(subscription.price.currencyFormatted())
                    .strikethrough()
                    .foregroundStyle(Theme.Palette.textSecondary.opacity(0.7))
                Text(L.t("· %@", cycle)).foregroundStyle(Theme.Palette.textSecondary)
            }
            .font(.subheadline)
            .foregroundStyle(Theme.Palette.textSecondary)
            .lineLimit(1)
        } else {
            Text(L.t("%@ · %@", subscription.price.currencyFormatted(), cycle))
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: Pastille de statut (Essai / Promo)

    @ViewBuilder
    private var statusTag: some View {
        if subscription.isInTrial {
            tag(L.t("Essai"), color: Color(hex: "#30D158"))
        } else if subscription.isPromoActive {
            tag(L.t("Promo"), color: Color(hex: "#FF9F0A"))
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background { Capsule().fill(color.opacity(0.16)) }
    }

    // MARK: Badge « prochain prélèvement »

    private var billingBadge: some View {
        let days = subscription.daysUntilNextBilling
        let isImminent = days >= 0 && days <= 3
        let tintColor: Color = isImminent ? Theme.Palette.appAccent : Theme.Palette.textSecondary

        return Text(billingText(forDays: days))
            .font(.caption.weight(.semibold))
            .foregroundStyle(tintColor)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background {
                Capsule(style: .continuous).fill(tintColor.opacity(0.14))
            }
    }

    private func billingText(forDays days: Int) -> String {
        switch days {
        case ..<0:  L.t("En retard")
        case 0:     L.t("Aujourd'hui")
        case 1:     L.t("Demain")
        default:    L.t("Dans %d j", days)
        }
    }

    private var accessibilityLabel: String {
        let status = subscription.isActive ? "" : L.t(", en pause")
        return L.t("%@, %@ %@", subscription.name, subscription.price.currencyFormatted(), subscription.billingCycle.displayName) + status
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack {
            SubscriptionRow(subscription: SeedDataProvider.makeCatalog()[0])
            SubscriptionRow(subscription: SeedDataProvider.makeCatalog()[12])
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
