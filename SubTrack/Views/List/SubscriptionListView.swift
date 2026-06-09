//
//  SubscriptionListView.swift
//  SubTrack
//
//  Écran d'accueil : total mensuel, filtre par catégorie, recherche, tri et
//  liste des abonnements. La Vue reste « bête » : recherche/filtre/tri/totaux
//  sont délégués à `SubscriptionListViewModel`, les données viennent d'un
//  `@Query` natif SwiftData (réactivité automatique).
//
//  NOTE Étapes 6 & 7 : la navigation vers le détail et la feuille d'ajout
//  utilisent pour l'instant des placeholders, remplacés aux étapes suivantes.
//

import SwiftUI
import SwiftData

struct SubscriptionListView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.haptics) private var haptics

    /// Source de vérité réactive : toute mutation SwiftData rafraîchit la vue.
    @Query(sort: \Subscription.nextBillingDate) private var subscriptions: [Subscription]

    /// VM sans dépendance (agrégats via `SubscriptionMetrics`) → pas de flash d'init.
    @State private var viewModel = SubscriptionListViewModel()
    @State private var isPresentingEditor = false

    /// Espace de noms partagé pour la transition zoom ligne → détail.
    @Namespace private var detailTransition

    var body: some View {
        NavigationStack {
            content(viewModel)
                .background(Theme.Palette.background.ignoresSafeArea())
                .navigationTitle(L.t("Abonnements"))
                .toolbar { toolbarContent }
                .navigationDestination(for: Subscription.self) { subscription in
                    SubscriptionDetailView(subscription: subscription)
                        .navigationTransition(.zoom(sourceID: subscription.id, in: detailTransition))
                }
                .sheet(isPresented: $isPresentingEditor) {
                    SubscriptionEditorView(
                        viewModel: SubscriptionEditorViewModel(
                            mode: .create,
                            service: SubscriptionService(context: context)
                        )
                    )
                }
        }
        .tint(Theme.Palette.appAccent)
        .onChange(of: subscriptions, initial: true) { _, newValue in
            viewModel.apply(subscriptions: newValue)
            Task { await NotificationScheduler.reschedule(for: newValue) }
        }
    }

    // MARK: Contenu principal

    @ViewBuilder
    private func content(_ viewModel: SubscriptionListViewModel) -> some View {
        if viewModel.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    TotalHeaderView(
                        monthlyTotal: viewModel.monthlyTotal,
                        yearlyTotal: viewModel.yearlyTotal,
                        activeCount: viewModel.activeCount
                    )

                    CategoryFilterBar(selection: bindingForCategory(viewModel))

                    if viewModel.hasNoResults {
                        noResultsState
                    } else {
                        ForEach(viewModel.displayedSubscriptions) { subscription in
                            row(subscription, viewModel: viewModel)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .scrollDismissesKeyboard(.immediately)
            .searchable(
                text: bindingForSearch(viewModel),
                prompt: L.t("Rechercher un abonnement")
            )
        }
    }

    private func row(_ subscription: Subscription, viewModel: SubscriptionListViewModel) -> some View {
        NavigationLink(value: subscription) {
            SubscriptionRow(subscription: subscription)
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: subscription.id, in: detailTransition)
        .contextMenu {
            Button {
                toggleActive(subscription)
            } label: {
                Label(
                    subscription.isActive ? L.t("Mettre en pause") : L.t("Réactiver"),
                    systemImage: subscription.isActive ? "pause.circle" : "play.circle"
                )
            }
            Button(role: .destructive) {
                delete(subscription)
            } label: {
                Label(L.t("Supprimer"), systemImage: "trash")
            }
        }
    }

    // MARK: États vides

    private var emptyState: some View {
        ContentUnavailableView {
            Label(L.t("Aucun abonnement"), systemImage: "tray")
        } description: {
            Text(L.t("Ajoutez votre premier abonnement pour suivre vos dépenses."))
        } actions: {
            Button(L.t("Ajouter"), systemImage: "plus") { isPresentingEditor = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView.search
            .padding(.top, Theme.Spacing.xl)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            sortMenu(viewModel)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresentingEditor = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(L.t("Ajouter un abonnement"))
        }
    }

    private func sortMenu(_ viewModel: SubscriptionListViewModel) -> some View {
        Menu {
            Picker(L.t("Trier par"), selection: bindingForSort(viewModel)) {
                ForEach(SubscriptionListViewModel.SortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel(L.t("Trier"))
    }

    // MARK: Actions (CRUD délégué au service construit à la volée)

    private func toggleActive(_ subscription: Subscription) {
        try? SubscriptionService(context: context).toggleActive(subscription)
        haptics.play(.medium)
    }

    private func delete(_ subscription: Subscription) {
        try? SubscriptionService(context: context).delete(subscription)
        haptics.play(.warning)
    }

    // MARK: Bindings vers le VM (@Observable)

    private func bindingForSearch(_ vm: SubscriptionListViewModel) -> Binding<String> {
        Binding(get: { vm.searchText }, set: { vm.searchText = $0 })
    }

    private func bindingForCategory(_ vm: SubscriptionListViewModel) -> Binding<SubscriptionCategory?> {
        Binding(get: { vm.selectedCategory }, set: { vm.selectedCategory = $0 })
    }

    private func bindingForSort(_ vm: SubscriptionListViewModel) -> Binding<SubscriptionListViewModel.SortOption> {
        Binding(get: { vm.sortOption }, set: { vm.sortOption = $0 })
    }

}

// MARK: - Barre de filtres par catégorie

/// Rangée horizontale de pastilles « verre » filtrant par catégorie.
private struct CategoryFilterBar: View {

    @Binding var selection: SubscriptionCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                chip(title: L.t("Tout"), symbol: "square.grid.2x2", isOn: selection == nil) {
                    selection = nil
                }
                ForEach(SubscriptionCategory.allCases) { category in
                    chip(
                        title: category.displayName,
                        symbol: category.symbolName,
                        tint: category.accentColor,
                        isOn: selection == category
                    ) {
                        selection = (selection == category) ? nil : category
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xxs)
        }
        .scrollClipDisabled()
    }

    private func chip(
        title: String,
        symbol: String,
        tint: Color = Theme.Palette.appAccent,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isOn ? .white : Theme.Palette.textPrimary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background {
                    Capsule(style: .continuous)
                        .fill(isOn ? AnyShapeStyle(tint) : AnyShapeStyle(.regularMaterial))
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Theme.Palette.glassBorder, lineWidth: Theme.Size.hairline)
                }
        }
        .buttonStyle(.plain)
        .hapticFeedback(.selection, trigger: isOn)
    }
}

#Preview {
    SubscriptionListView()
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
