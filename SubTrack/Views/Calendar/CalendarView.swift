//
//  CalendarView.swift
//  SubTrack
//
//  Vue calendrier : grille mensuelle marquant les jours de prélèvement, avec
//  le total du mois et la liste des prélèvements du jour sélectionné.
//

import SwiftUI
import SwiftData

struct CalendarView: View {

    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]
    @State private var viewModel = CalendarViewModel()

    /// Espace de noms partagé pour la transition zoom ligne → détail.
    @Namespace private var detailTransition

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    monthCard
                    selectedDayCard
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .navigationTitle(L.t("Calendrier"))
            .navigationDestination(for: Subscription.self) { subscription in
                SubscriptionDetailView(subscription: subscription)
                    .navigationTransition(.zoom(sourceID: subscription.id, in: detailTransition))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.t("Aujourd'hui")) { withAnimation(.snappy) { viewModel.goToToday() } }
                }
            }
        }
        .tint(Theme.Palette.appAccent)
        .onChange(of: subscriptions, initial: true) { _, newValue in
            viewModel.apply(subscriptions: newValue)
        }
    }

    // MARK: Carte du mois (en-tête + grille)

    private var monthCard: some View {
        GlassCard(padding: Theme.Spacing.md) {
            VStack(spacing: Theme.Spacing.sm) {
                header
                weekdayHeader
                grid
                Divider().overlay(Theme.Palette.glassBorder)
                HStack {
                    Text(L.t("Total du mois"))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.textSecondary)
                    Spacer()
                    Text(viewModel.monthTotal.currencyFormatted())
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.textPrimary)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { withAnimation(.snappy) { viewModel.goToPreviousMonth() } } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            Spacer()
            Text(viewModel.monthTitle.capitalized)
                .font(.headline)
                .foregroundStyle(Theme.Palette.textPrimary)
                .contentTransition(.numericText())
            Spacer()
            Button { withAnimation(.snappy) { viewModel.goToNextMonth() } } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.Palette.appAccent)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.gridDays, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = viewModel.isInDisplayedMonth(day)
        let selected = viewModel.isSelected(day)
        let today = viewModel.isToday(day)

        return Button {
            withAnimation(.snappy) { viewModel.select(day) }
        } label: {
            VStack(spacing: 3) {
                Text(day.formatted(.dateTime.day().locale(AppLocale.current)))
                    .font(.callout.weight(today ? .bold : .regular))
                    .foregroundStyle(dayTextColor(inMonth: inMonth, selected: selected, today: today))
                Circle()
                    .fill(viewModel.hasBillings(on: day) ? Theme.Palette.appAccent : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.Palette.appAccent.opacity(0.18))
                } else if today {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.Palette.appAccent.opacity(0.5), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(inMonth ? 1 : 0.3)
    }

    private func dayTextColor(inMonth: Bool, selected: Bool, today: Bool) -> Color {
        if selected || today { return Theme.Palette.appAccent }
        return Theme.Palette.textPrimary
    }

    // MARK: Carte du jour sélectionné

    private var selectedDayCard: some View {
        let items = viewModel.subscriptions(on: viewModel.selectedDay)
        return GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(viewModel.selectedDay.formatted(.dateTime.weekday(.wide).day().month().locale(AppLocale.current)))
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                    if !items.isEmpty {
                        Text(viewModel.total(on: viewModel.selectedDay).currencyFormatted())
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                }

                if items.isEmpty {
                    Text(L.t("Aucun prélèvement ce jour-là."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.Spacing.xs)
                } else {
                    ForEach(items) { sub in
                        NavigationLink(value: sub) {
                            HStack(spacing: Theme.Spacing.sm) {
                                IconBadge(systemName: sub.iconSystemName, tint: Color(hex: sub.accentColorHex),
                                          brandName: sub.name, domain: sub.brandDomain, size: 34)
                                Text(sub.name)
                                    .foregroundStyle(Theme.Palette.textPrimary)
                                Spacer()
                                Text(sub.effectivePrice.currencyFormatted(currencyCode: sub.currencyCode))
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Palette.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.Palette.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: sub.id, in: detailTransition)
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
