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

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        TabView {
            Tab("Abonnements", systemImage: "list.bullet.rectangle.fill") {
                SubscriptionListView()
            }
            Tab("Calendrier", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Statistiques", systemImage: "chart.pie.fill") {
                StatsView()
            }
            Tab("Réglages", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(Theme.Palette.appAccent)
        .preferredColorScheme(appearance.colorScheme)
    }
}

#Preview {
    AppRootView()
        .modelContainer(PreviewData.container)
}
