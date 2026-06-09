//
//  AppRootView.swift
//  SubTrack
//
//  Vue racine : `TabView` à quatre onglets (Abonnements / Calendrier /
//  Statistiques / Réglages) via la nouvelle API `Tab` (iOS 18).
//

import SwiftUI

struct AppRootView: View {

    @AppStorage(PreferenceKey.appearanceMode) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(PreferenceKey.appLanguage) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage(PreferenceKey.currencyCode) private var currencyRaw = AppCurrency.eur.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    /// Recomposé à chaque changement de langue ou de devise. Appliqué en `.id`
    /// sur le contenu des onglets, il force la reconstruction de leurs vues pour
    /// que tous les libellés (`L.t`) et montants (`currencyFormatted`) reflètent
    /// immédiatement le nouveau réglage, sans relancer l'app. L'onglet Réglages
    /// se met à jour seul (il observe déjà ces préférences via `@AppStorage`).
    private var localizationToken: String { "\(languageRaw)-\(currencyRaw)" }

    var body: some View {
        TabView {
            Tab(L.t("Abonnements"), systemImage: "list.bullet.rectangle.fill") {
                SubscriptionListView().id(localizationToken)
            }
            Tab(L.t("Calendrier"), systemImage: "calendar") {
                CalendarView().id(localizationToken)
            }
            Tab(L.t("Statistiques"), systemImage: "chart.pie.fill") {
                StatsView().id(localizationToken)
            }
            Tab(L.t("Réglages"), systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(Theme.Palette.appAccent)
        .preferredColorScheme(appearance.colorScheme)
        .environment(\.locale, language.locale ?? .autoupdatingCurrent)
    }
}

#Preview {
    AppRootView()
        .modelContainer(PreviewData.container)
}
