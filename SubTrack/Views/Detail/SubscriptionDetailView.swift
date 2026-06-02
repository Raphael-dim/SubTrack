//
//  SubscriptionDetailView.swift
//  SubTrack
//
//  Détail d'un abonnement : coûts (réel, mensualisé, annualisé), prochain
//  prélèvement, métadonnées, et actions (éditer / pause / supprimer).
//  Affichage piloté par le `@Model` (réactif) ; les mutations passent par
//  le `SubscriptionService`.
//
//  NOTE Étape 7 : le bouton « Modifier » ouvre pour l'instant un placeholder,
//  remplacé par `SubscriptionEditorView` à l'étape suivante.
//

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {

    let subscription: Subscription

    @Environment(\.modelContext) private var context
    @Environment(\.haptics) private var haptics
    @Environment(\.dismiss) private var dismiss

    @State private var isPresentingEditor = false
    @State private var isConfirmingDelete = false

    private var tint: Color { Color(hex: subscription.accentColorHex) }
    private var service: SubscriptionService { SubscriptionService(context: context) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                header
                priceCard
                infoCard
                if let notes = subscription.notes, !notes.isEmpty {
                    notesCard(notes)
                }
                pauseButton
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Palette.background.ignoresSafeArea())
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Modifier") { isPresentingEditor = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
                .accessibilityLabel("Supprimer")
            }
        }
        .confirmationDialog(
            "Supprimer « \(subscription.name) » ?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive, action: deleteSubscription)
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est définitive.")
        }
        .sheet(isPresented: $isPresentingEditor) {
            SubscriptionEditorView(
                viewModel: SubscriptionEditorViewModel(
                    mode: .edit(subscription),
                    service: service
                )
            )
        }
    }

    // MARK: En-tête

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            IconBadge(
                systemName: subscription.iconSystemName,
                tint: tint,
                brandName: subscription.name,
                domain: subscription.brandDomain,
                size: 80
            )

            Text(subscription.name)
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.Palette.textPrimary)
                .multilineTextAlignment(.center)

            categoryChip
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xs)
    }

    private var categoryChip: some View {
        Label(subscription.category.displayName, systemImage: subscription.category.symbolName)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(subscription.category.accentColor)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                Capsule(style: .continuous)
                    .fill(subscription.category.accentColor.opacity(0.16))
            }
    }

    // MARK: Carte prix

    private var priceCard: some View {
        GlassCard(padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(subscription.price.currencyFormatted(currencyCode: subscription.currencyCode))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text("par \(subscription.billingCycle.displayName.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }

                Divider().overlay(Theme.Palette.glassBorder)

                HStack {
                    metric(
                        title: "Soit / mois",
                        value: subscription.monthlyEquivalent.currencyFormatted(currencyCode: subscription.currencyCode)
                    )
                    Spacer()
                    metric(
                        title: "Soit / an",
                        value: subscription.yearlyEquivalent.currencyFormatted(currencyCode: subscription.currencyCode),
                        alignment: .trailing
                    )
                }
            }
        }
    }

    private func metric(title: String, value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.Palette.textPrimary)
        }
    }

    // MARK: Carte infos

    private var infoCard: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.sm) {
                infoRow(
                    icon: "calendar.badge.clock",
                    label: "Prochain prélèvement",
                    value: subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted),
                    accessory: billingCountdown
                )
                Divider().overlay(Theme.Palette.glassBorder)
                infoRow(
                    icon: "calendar",
                    label: "Souscrit le",
                    value: subscription.startDate.formatted(date: .abbreviated, time: .omitted)
                )
                Divider().overlay(Theme.Palette.glassBorder)
                infoRow(
                    icon: subscription.isActive ? "checkmark.seal.fill" : "pause.circle.fill",
                    label: "Statut",
                    value: subscription.isActive ? "Actif" : "En pause"
                )

                if subscription.isInTrial, let trialEnd = subscription.trialEndDate {
                    Divider().overlay(Theme.Palette.glassBorder)
                    infoRow(
                        icon: "gift.fill",
                        label: "Essai gratuit",
                        value: "jusqu'au \(trialEnd.formatted(date: .abbreviated, time: .omitted))",
                        accessory: subscription.daysUntilTrialEnds.map { "dans \($0) j" }
                    )
                }

                if subscription.isPromoActive, let promo = subscription.promoPrice {
                    Divider().overlay(Theme.Palette.glassBorder)
                    infoRow(
                        icon: "tag.fill",
                        label: "Prix promotionnel",
                        value: promo.currencyFormatted(currencyCode: subscription.currencyCode),
                        accessory: subscription.promoEndDate.map { "jusqu'au \($0.formatted(date: .abbreviated, time: .omitted))" }
                    )
                }

                Divider().overlay(Theme.Palette.glassBorder)
                infoRow(
                    icon: subscription.notificationsEnabled ? "bell.fill" : "bell.slash.fill",
                    label: "Rappels",
                    value: subscription.notificationsEnabled ? "Activés" : "Désactivés"
                )
            }
        }
    }

    private func infoRow(icon: String, label: String, value: String, accessory: String? = nil) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(Theme.Palette.textSecondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(value)
                    .foregroundStyle(Theme.Palette.textPrimary)
                if let accessory {
                    Text(accessory)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
            }
        }
        .font(.subheadline)
    }

    private var billingCountdown: String {
        let days = subscription.daysUntilNextBilling
        switch days {
        case ..<0: return "en retard"
        case 0:    return "aujourd'hui"
        case 1:    return "demain"
        default:   return "dans \(days) jours"
        }
    }

    // MARK: Carte notes

    private func notesCard(_ notes: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Label("Notes", systemImage: "note.text")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text(notes)
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
        }
    }

    // MARK: Bouton pause / réactiver

    private var pauseButton: some View {
        Button(action: toggleActive) {
            Label(
                subscription.isActive ? "Mettre en pause" : "Réactiver",
                systemImage: subscription.isActive ? "pause.fill" : "play.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.Palette.textPrimary)
        .glassBackground(cornerRadius: Theme.Radius.chip)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: Actions

    private func toggleActive() {
        try? service.toggleActive(subscription)
        haptics.play(.medium)
    }

    private func deleteSubscription() {
        haptics.play(.warning)
        try? service.delete(subscription)
        dismiss()
    }

}

#Preview {
    NavigationStack {
        SubscriptionDetailView(subscription: SeedDataProvider.makeCatalog()[0])
    }
    .modelContainer(PreviewData.container)
    .preferredColorScheme(.dark)
}
