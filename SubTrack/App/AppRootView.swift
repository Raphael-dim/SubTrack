//
//  AppRootView.swift
//  SubTrack
//
//  Vue racine : `TabView` à deux onglets (Abonnements / Statistiques) via la
//  nouvelle API `Tab` (iOS 18).
//

import SwiftUI

struct AppRootView: View {

    @AppStorage(PreferenceKey.appearanceMode) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(PreferenceKey.appLanguage) private var languageRaw = AppLanguage.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        TabView {
            Tab(L.t("Abonnements"), systemImage: "list.bullet.rectangle.fill") {
                SubscriptionListView()
            }
            Tab(L.t("Calendrier"), systemImage: "calendar") {
                CalendarView()
            }
            Tab(L.t("Statistiques"), systemImage: "chart.pie.fill") {
                StatsView()
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
