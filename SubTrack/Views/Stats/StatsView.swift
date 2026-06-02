//
//  StatsView.swift
//  SubTrack
//
//  Tableau de bord des dépenses : totaux, donut par catégorie, détail par
//  catégorie et point d'attention (abonnement le plus cher). Données fournies
//  par `@Query` et agrégées dans `StatsViewModel` (aucune logique ici).
//

import SwiftUI
import SwiftData

struct StatsView: View {

    @Query private var subscriptions: [Subscription]

    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            content(viewModel)
                .background(Theme.Palette.background.ignoresSafeArea())
                .navigationTitle("Statistiques")
        }
        .onChange(of: subscriptions, initial: true) { _, newValue in
            viewModel.apply(subscriptions: newValue)
        }
    }

    @ViewBuilder
    private func content(_ viewModel: StatsViewModel) -> some View {
        if !viewModel.hasData {
            ContentUnavailableView(
                "Aucune donnée",
                systemImage: "chart.pie",
                description: Text("Ajoutez des abonnements actifs pour voir vos statistiques.")
            )
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    totalsCard(viewModel)
                    donutCard(viewModel)
                    breakdownCard(viewModel)
                    if let priciest = viewModel.mostExpensive {
                        highlightCard(priciest)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
    }

    // MARK: Totaux

    private func totalsCard(_ viewModel: StatsViewModel) -> some View {
        GlassCard(padding: Theme.Spacing.lg) {
            HStack {
                totalMetric(
                    title: "Par mois",
                    value: viewModel.monthlyTotal.currencyFormatted()
                )
                Spacer()
                Divider().frame(height: 40).overlay(Theme.Palette.glassBorder)
                Spacer()
                totalMetric(
                    title: "Par an",
                    value: viewModel.yearlyTotal.currencyFormatted(),
                    alignment: .trailing
                )
            }
        }
    }

    private func totalMetric(title: String, value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.textSecondary)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Palette.textPrimary)
        }
    }

    // MARK: Donut

    private func donutCard(_ viewModel: StatsViewModel) -> some View {
        GlassCard(padding: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Répartition par catégorie")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.textPrimary)
                CategoryDonutChart(
                    breakdown: viewModel.breakdown,
                    centerTotal: viewModel.monthlyTotal
                )
            }
        }
    }

    // MARK: Détail par catégorie

    private func breakdownCard(_ viewModel: StatsViewModel) -> some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(viewModel.breakdown.enumerated()), id: \.element.id) { index, item in
                    breakdownRow(item)
                    if index < viewModel.breakdown.count - 1 {
                        Divider().overlay(Theme.Palette.glassBorder)
                    }
                }
            }
        }
    }

    private func breakdownRow(_ item: CategoryBreakdown) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: item.category.symbolName)
                .foregroundStyle(item.category.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("\(item.subscriptionCount) abonnement\(item.subscriptionCount > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.monthlyTotal.currencyFormatted())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
    }

    // MARK: Point d'attention

    private func highlightCard(_ subscription: Subscription) -> some View {
        GlassCard {
            HStack(spacing: Theme.Spacing.sm) {
                IconBadge(
                    systemName: subscription.iconSystemName,
                    tint: Color(hex: subscription.accentColorHex),
                    brandName: subscription.name,
                    domain: subscription.brandDomain
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Poste le plus coûteux")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                    Text(subscription.name)
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.textPrimary)
                }
                Spacer()
                Text("\(subscription.monthlyEquivalent.currencyFormatted()) / mois")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
        }
    }

}

#Preview {
    StatsView()
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
