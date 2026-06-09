//
//  SubscriptionEditorView.swift
//  SubTrack
//
//  Formulaire unifié d'ajout ET d'édition (DRY). Toute la logique (validation,
//  parsing du prix, persistance) vit dans `SubscriptionEditorViewModel` ; cette
//  vue ne fait que lier les champs et présenter les sélecteurs couleur / icône.
//

import SwiftUI

struct SubscriptionEditorView: View {

    @State private var viewModel: SubscriptionEditorViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.haptics) private var haptics

    /// Focus du champ « Nom » : pilote l'affichage du menu flottant de suggestions.
    @FocusState private var nameFocused: Bool

    /// Le VM (déjà câblé à un service) est injecté par la vue présentatrice.
    init(viewModel: SubscriptionEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // Palettes proposées (l'utilisateur reste libre de choisir).
    private static let presetColors = [
        "#FF453A", "#FF9F0A", "#FFD60A", "#30D158", "#0A84FF",
        "#5E5CE6", "#BF5AF2", "#FF375F", "#64D2FF", "#1C1C1E"
    ]
    private static let presetSymbols = [
        "creditcard.fill", "play.rectangle.fill", "music.note", "sparkles.tv.fill",
        "film.stack.fill", "tv.fill", "icloud.fill", "brain.head.profile",
        "paintbrush.pointed.fill", "desktopcomputer", "note.text", "figure.run",
        "dumbbell.fill", "bolt.fill", "flame.fill", "drop.fill", "wifi",
        "antenna.radiowaves.left.and.right", "tram.fill", "car.fill", "house.fill",
        "cross.case.fill", "shield.lefthalf.filled", "banknote.fill", "cart.fill",
        "gamecontroller.fill", "book.fill", "newspaper.fill", "cloud.fill", "bag.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                detailsSection(viewModel)
                billingSection(viewModel)
                trialAndPromoSection(viewModel)
                notificationsSection(viewModel)
                appearanceSection(viewModel)
                if viewModel.isEditing {
                    statusSection(viewModel)
                }
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            // Menu flottant de suggestions, ancré juste sous le champ « Nom ».
            .overlayPreferenceValue(NameFieldBoundsKey.self) { anchor in
                GeometryReader { proxy in
                    if showSuggestions, let anchor {
                        let rect = proxy[anchor]
                        floatingSuggestions
                            .frame(width: rect.width)
                            .offset(x: rect.minX, y: rect.maxY + 6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("Annuler")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("Enregistrer"), action: save)
                        .fontWeight(.semibold)
                        .disabled(!viewModel.canSave)
                }
            }
        }
    }

    // MARK: Suggestions flottantes (autocomplétion sous le champ « Nom »)

    /// Visible uniquement quand le champ nom a le focus et qu'il existe des
    /// correspondances dans le catalogue connu.
    private var showSuggestions: Bool {
        nameFocused && !viewModel.suggestions.isEmpty
    }

    private var floatingSuggestions: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.suggestions.prefix(6).enumerated()), id: \.element.id) { index, template in
                Button {
                    viewModel.apply(template: template)
                    haptics.play(.selection)
                    nameFocused = false
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        IconBadge(
                            systemName: template.iconSystemName,
                            tint: template.accentColor,
                            brandName: template.name,
                            domain: template.brandDomain,
                            size: 30
                        )
                        Text(template.name)
                            .foregroundStyle(Theme.Palette.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(template.suggestedPrice.currencyFormatted())
                            .font(.subheadline)
                            .foregroundStyle(Theme.Palette.textSecondary)
                    }
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < min(viewModel.suggestions.count, 6) - 1 {
                    Divider().overlay(Theme.Palette.glassBorder)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                .strokeBorder(Theme.Palette.glassBorder, lineWidth: Theme.Size.hairline)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Détails

    private func detailsSection(@Bindable _ vm: SubscriptionEditorViewModel) -> some View {
        Section(L.t("Détails")) {
            HStack(spacing: Theme.Spacing.sm) {
                IconBadge(
                    systemName: vm.iconSystemName,
                    tint: Color(hex: vm.accentColorHex),
                    brandName: vm.name,
                    domain: vm.brandDomain,
                    size: 30
                )
                TextField(L.t("Nom"), text: $vm.name)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
            }
            .anchorPreference(key: NameFieldBoundsKey.self, value: .bounds) { $0 }

            HStack {
                TextField(L.t("Prix"), text: $vm.priceText)
                    .keyboardType(.decimalPad)
                Text(AppCurrency.current.symbol).foregroundStyle(Theme.Palette.textSecondary)
            }

            Picker(L.t("Catégorie"), selection: $vm.category) {
                ForEach(SubscriptionCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.symbolName).tag(category)
                }
            }
        }
    }

    // MARK: Facturation

    private func billingSection(@Bindable _ vm: SubscriptionEditorViewModel) -> some View {
        Section(L.t("Facturation")) {
            Picker(L.t("Périodicité"), selection: $vm.billingCycle) {
                ForEach(BillingCycle.allCases) { cycle in
                    Text(cycle.displayName).tag(cycle)
                }
            }
            DatePicker(L.t("Début de l'abonnement"), selection: $vm.startDate, displayedComponents: .date)
            DatePicker(L.t("Prochain prélèvement"), selection: $vm.nextBillingDate, displayedComponents: .date)
        }
    }

    // MARK: Essai gratuit & remise

    @ViewBuilder
    private func trialAndPromoSection(@Bindable _ vm: SubscriptionEditorViewModel) -> some View {
        Section(L.t("Essai gratuit")) {
            Toggle(isOn: $vm.hasTrial) {
                Label(L.t("En période d'essai"), systemImage: "gift.fill")
            }
            if vm.hasTrial {
                DatePicker(L.t("Fin de l'essai"), selection: $vm.trialEndDate, displayedComponents: .date)
            }
        }

        Section {
            Toggle(isOn: $vm.hasPromo) {
                Label(L.t("Prix promotionnel"), systemImage: "tag.fill")
            }
            if vm.hasPromo {
                HStack {
                    TextField(L.t("Prix promo"), text: $vm.promoPriceText)
                        .keyboardType(.decimalPad)
                    Text(AppCurrency.current.symbol).foregroundStyle(Theme.Palette.textSecondary)
                }
                Toggle(L.t("Date de fin de promo"), isOn: $vm.hasPromoEnd)
                if vm.hasPromoEnd {
                    DatePicker(L.t("Fin de la promo"), selection: $vm.promoEndDate, displayedComponents: .date)
                }
            }
        } header: {
            Text(L.t("Remise"))
        } footer: {
            if vm.hasTrial {
                Text(L.t("Pendant l'essai, le coût compté est de 0 €."))
            }
        }
    }

    // MARK: Notifications (par abonnement)

    private func notificationsSection(@Bindable _ vm: SubscriptionEditorViewModel) -> some View {
        Section {
            Toggle(isOn: $vm.notificationsEnabled) {
                Label(L.t("Me rappeler les échéances"), systemImage: "bell.badge.fill")
            }
        } footer: {
            Text(L.t("Le rappel global et son délai se règlent dans Réglages."))
        }
    }

    // MARK: Apparence (couleur + icône)

    private func appearanceSection(@Bindable _ vm: SubscriptionEditorViewModel) -> some View {
        Section(L.t("Apparence")) {
            colorPicker(vm)
            symbolPicker(vm)
        }
    }

    private func colorPicker(_ vm: SubscriptionEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(L.t("Couleur")).font(.subheadline).foregroundStyle(Theme.Palette.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Self.presetColors, id: \.self) { hex in
                        swatch(hex: hex, isSelected: vm.accentColorHex == hex) {
                            vm.accentColorHex = hex
                            haptics.play(.selection)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xxs)
            }
        }
    }

    private func swatch(hex: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 30, height: 30)
                .overlay { Circle().strokeBorder(.white, lineWidth: isSelected ? 3 : 0) }
                .overlay { Circle().strokeBorder(Theme.Palette.glassBorder, lineWidth: 1) }
                .scaleEffect(isSelected ? 1.12 : 1)
                .animation(.snappy, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func symbolPicker(_ vm: SubscriptionEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(L.t("Icône")).font(.subheadline).foregroundStyle(Theme.Palette.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Theme.Spacing.sm) {
                // Logo de marque connu : première tuile sélectionnable. Elle est
                // active à l'ouverture tant que l'utilisateur n'a pas choisi un
                // SF Symbol — c'est ce qui correspond au logo réellement affiché.
                if vm.hasBrandLogoOption {
                    brandLogoCell(vm)
                }
                ForEach(Self.presetSymbols, id: \.self) { symbol in
                    // Tant que le logo de marque est actif, aucun symbole n'est surligné.
                    let isSelected = !vm.usesBrandLogo && vm.iconSystemName == symbol
                    Button {
                        vm.selectSymbol(symbol)
                        haptics.play(.selection)
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isSelected ? .white : Theme.Palette.textPrimary)
                            .frame(width: 40, height: 40)
                            .background {
                                RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous)
                                    .fill(isSelected ? AnyShapeStyle(Color(hex: vm.accentColorHex)) : AnyShapeStyle(.quaternary))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Theme.Spacing.xxs)
        }
    }

    /// Tuile « logo de marque » : affiche le vrai logo distant et, sélectionnée,
    /// le réactive comme icône de l'abonnement (prioritaire sur les SF Symbols).
    private func brandLogoCell(_ vm: SubscriptionEditorViewModel) -> some View {
        Button {
            vm.selectBrandLogo()
            haptics.play(.selection)
        } label: {
            IconBadge(
                systemName: vm.iconSystemName,
                tint: Color(hex: vm.accentColorHex),
                brandName: vm.name,
                domain: vm.knownBrandDomain,
                size: 40
            )
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous)
                    .strokeBorder(Color(hex: vm.accentColorHex), lineWidth: vm.usesBrandLogo ? 2.5 : 0)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Statut (édition uniquement)

    private func statusSection(@Bindable _ vm: SubscriptionEditorViewModel) -> some View {
        Section {
            Toggle(L.t("Abonnement actif"), isOn: $vm.isActive)
        } footer: {
            Text(L.t("Désactivez pour mettre en pause sans supprimer l'historique."))
        }
    }

    // MARK: Actions

    private func save() {
        do {
            try viewModel.save()
            haptics.play(.success)
            dismiss()
        } catch {
            haptics.play(.error)
        }
    }
}

// MARK: - Ancre du champ « Nom »

/// Transporte les bornes du champ « Nom » jusqu'à l'overlay, pour positionner
/// le menu flottant de suggestions exactement sous le champ.
private struct NameFieldBoundsKey: SwiftUI.PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
