//
//  CategoryDonutChart.swift
//  SubTrack
//
//  Donut de répartition des dépenses mensuelles par catégorie (Swift Charts).
//  Composant pur : reçoit des `CategoryBreakdown` déjà agrégés (aucun calcul
//  ici) et affiche le total au centre.
//

import SwiftUI
import Charts

struct CategoryDonutChart: View {

    let breakdown: [CategoryBreakdown]
    let centerTotal: Decimal

    var body: some View {
        Chart(breakdown) { item in
            SectorMark(
                angle: .value("Montant", item.monthlyTotal.doubleValue),
                innerRadius: .ratio(0.64),
                angularInset: 2
            )
            .cornerRadius(6)
            .foregroundStyle(by: .value("Catégorie", item.category.displayName))
        }
        .chartForegroundStyleScale(colorScale)
        .chartLegend(.hidden)
        .frame(height: 200)
        .overlay { centerLabel }
        .accessibilityLabel("Répartition des dépenses mensuelles par catégorie")
        .accessibilityValue(accessibilitySummary)
    }

    /// Résumé textuel du donut pour VoiceOver (le graphique n'est pas lisible seul).
    private var accessibilitySummary: String {
        breakdown
            .map { "\($0.category.displayName) \($0.share.formatted(.percent.precision(.fractionLength(0))))" }
            .joined(separator: ", ")
    }

    /// Associe chaque catégorie présente à sa couleur d'accentuation.
    private var colorScale: KeyValuePairs<String, Color> {
        // KeyValuePairs ne se construit pas dynamiquement ; on couvre les 4 cas.
        KeyValuePairs(dictionaryLiteral:
            (SubscriptionCategory.entertainment.displayName, SubscriptionCategory.entertainment.accentColor),
            (SubscriptionCategory.productivity.displayName, SubscriptionCategory.productivity.accentColor),
            (SubscriptionCategory.dailyLife.displayName, SubscriptionCategory.dailyLife.accentColor),
            (SubscriptionCategory.insuranceAndBanking.displayName, SubscriptionCategory.insuranceAndBanking.accentColor)
        )
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text("par mois")
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
            Text(centerTotal.currencyFormatted())
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.Palette.textPrimary)
        }
    }
}

#Preview {
    let catalog = SeedDataProvider.makeCatalog()
    return ZStack {
        Theme.Palette.background.ignoresSafeArea()
        CategoryDonutChart(
            breakdown: SubscriptionMetrics.breakdownByCategory(for: catalog),
            centerTotal: SubscriptionMetrics.monthlyTotal(for: catalog)
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
