//
//  ServiceCatalog.swift
//  SubTrack
//
//  Catalogue de référence des services connus (Netflix, Spotify, EDF…).
//  Source UNIQUE (DRY) utilisée à la fois par :
//   • le seeder (SeedDataProvider) pour pré-remplir la base au 1er lancement ;
//   • l'éditeur, pour l'autocomplétion (« je tape "net" → on me propose Netflix »).
//
//  Un `ServiceTemplate` ne porte que les infos intrinsèques d'un service
//  (nom, domaine de marque, couleur, prix indicatif, périodicité) — jamais de
//  date de prélèvement, qui est propre à chaque abonnement de l'utilisateur.
//  Le logo est récupéré à distance à partir du domaine (voir `BrandLogo`).
//

import SwiftUI

struct ServiceTemplate: Identifiable, Hashable {
    let name: String
    var category: SubscriptionCategory
    let accentColorHex: String
    let brandDomain: String?
    let iconSystemName: String
    let suggestedPrice: Decimal
    let billingCycle: BillingCycle

    var id: String { name }
    var accentColor: Color { Color(hex: accentColorHex) }
}

enum ServiceCatalog {

    /// L'intégralité des services connus, toutes catégories confondues.
    static let all: [ServiceTemplate] =
        entertainment + productivity + dailyLife + finance

    /// Services correspondant à une requête de recherche, classés par pertinence
    /// (préfixe d'abord), en excluant une correspondance déjà exactement saisie.
    static func matching(_ query: String, limit: Int = 8) -> [ServiceTemplate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()

        return all
            .filter { $0.name.localizedCaseInsensitiveContains(trimmed) && $0.name.lowercased() != lower }
            .sorted { lhs, rhs in
                let lp = lhs.name.lowercased().hasPrefix(lower)
                let rp = rhs.name.lowercased().hasPrefix(lower)
                if lp != rp { return lp }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Données par catégorie

    private static let entertainment: [ServiceTemplate] = section(.entertainment, [
        t("Netflix", 13.49, .monthly, "#E50914", domain: "netflix.com"),
        t("Spotify Premium", 11.99, .monthly, "#1ED760", domain: "spotify.com"),
        t("Disney+", 8.99, .monthly, "#113CCF", domain: "disneyplus.com"),
        t("Prime Video", 6.99, .monthly, "#1399FF", domain: "primevideo.com"),
        t("YouTube Premium", 12.99, .monthly, "#FF0000", domain: "youtube.com"),
        t("Apple TV+", 9.99, .monthly, "#000000", domain: "apple.com"),
        t("Apple Music", 10.99, .monthly, "#FA243C", domain: "music.apple.com"),
        t("Max", 9.99, .monthly, "#002BE7", domain: "max.com"),
        t("Paramount+", 7.99, .monthly, "#0064FF", domain: "paramountplus.com"),
        t("Crunchyroll", 6.49, .monthly, "#F47521", domain: "crunchyroll.com"),
        t("Deezer", 11.99, .monthly, "#A238FF", domain: "deezer.com"),
        t("DAZN", 29.99, .monthly, "#1A1A1A", domain: "dazn.com"),
        t("The New York Times", 17.00, .monthly, "#000000", domain: "nytimes.com"),
        t("YouTube Music", 10.99, .monthly, "#FF0000", domain: "music.youtube.com"),
        t("Amazon Music", 10.99, .monthly, "#25D1DA", domain: "music.amazon.com"),
        t("SoundCloud Go+", 5.99, .monthly, "#FF5500", domain: "soundcloud.com"),
        t("TIDAL", 10.99, .monthly, "#1A1A1A", domain: "tidal.com"),
        t("Molotov+", 3.99, .monthly, "#1A1A1A", domain: "molotov.tv"),
        t("Le Monde", 11.99, .monthly, "#000000", domain: "lemonde.fr"),
        t("PlayStation Plus", 8.99, .monthly, "#0070D1", domain: "playstation.com"),
        t("Xbox Game Pass", 12.99, .monthly, "#107C10", domain: "xbox.com"),
        t("Nintendo Switch Online", 3.99, .monthly, "#E60012", domain: "nintendo.com"),
    ])

    private static let productivity: [ServiceTemplate] = section(.productivity, [
        t("iCloud+ 200 Go", 2.99, .monthly, "#3693F3", domain: "icloud.com"),
        t("Google One", 1.99, .monthly, "#4285F4", domain: "google.com"),
        t("Dropbox", 11.99, .monthly, "#0061FF", domain: "dropbox.com"),
        t("Notion Plus", 9.99, .monthly, "#000000", domain: "notion.so"),
        t("Slack", 7.25, .monthly, "#4A154B", domain: "slack.com"),
        t("Adobe Creative Cloud", 60.99, .monthly, "#DA1F26", domain: "adobe.com"),
        t("Figma", 12.00, .monthly, "#F24E1E", domain: "figma.com"),
        t("GitHub Copilot", 10.00, .monthly, "#181717", domain: "github.com"),
        t("1Password", 2.99, .monthly, "#145FE4", domain: "1password.com"),
        t("NordVPN", 11.99, .monthly, "#4687FF", domain: "nordvpn.com"),
        t("Canva Pro", 11.99, .monthly, "#00C4CC", domain: "canva.com"),
        t("ChatGPT Plus", 22.99, .monthly, "#10A37F", domain: "openai.com"),
        t("Claude Pro", 21.99, .monthly, "#D97757", domain: "claude.ai"),
        t("Perplexity Pro", 20.00, .monthly, "#1FB8CD", domain: "perplexity.ai"),
        t("Microsoft 365", 99.00, .yearly, "#D83B01", domain: "microsoft.com"),
        t("Infomaniak kSuite", 9.99, .monthly, "#0098FF", domain: "infomaniak.com"),
        t("LinkedIn Premium", 29.99, .monthly, "#0A66C2", domain: "linkedin.com"),
        t("Zoom Pro", 13.99, .monthly, "#0B5CFF", domain: "zoom.us"),
        t("Bitwarden Premium", 0.83, .monthly, "#175DDC", domain: "bitwarden.com"),
        t("Proton VPN Plus", 9.99, .monthly, "#6D4AFF", domain: "protonvpn.com"),
        t("Surfshark VPN", 12.95, .monthly, "#1EBFBF", domain: "surfshark.com"),
    ])

    private static let dailyLife: [ServiceTemplate] = section(.dailyLife, [
        t("Basic-Fit", 19.99, .monthly, "#FF6600", domain: "basic-fit.com"),
        t("Électricité EDF", 89.00, .monthly, "#1428A0", domain: "edf.fr"),
        t("Gaz Engie", 64.50, .monthly, "#0F9D58", domain: "engie.fr"),
        t("Orange Livebox", 39.99, .monthly, "#FF7900", domain: "orange.fr"),
        t("Bouygues Telecom", 29.99, .monthly, "#0096D6", domain: "bouyguestelecom.fr"),
        t("Free Mobile", 19.99, .monthly, "#CD1E25", domain: "free.fr"),
        t("SFR Fibre", 39.99, .monthly, "#E2001A", domain: "sfr.fr"),
        t("Sosh", 14.99, .monthly, "#E5007D", domain: "sosh.fr"),
        t("Navigo", 88.80, .monthly, "#003DA5", symbol: "tram.fill"),
        t("Amazon Prime", 6.99, .monthly, "#FF9900", domain: "amazon.com"),
        t("Uber Eats Pass", 5.99, .monthly, "#06C167", domain: "ubereats.com"),
        t("Deliveroo Plus", 3.49, .monthly, "#00CCBC", domain: "deliveroo.com"),
        t("HelloFresh", 49.90, .monthly, "#99CC33", domain: "hellofresh.com"),
        t("Carte Avantage SNCF", 49.00, .yearly, "#8C1D40", domain: "sncf.com"),
    ])

    private static let finance: [ServiceTemplate] = section(.insuranceAndBanking, [
        t("Mutuelle Santé", 45.00, .monthly, "#00897B", symbol: "cross.case.fill"),
        t("Assurance Auto", 62.00, .monthly, "#37474F", symbol: "car.fill"),
        t("Assurance Habitation", 18.50, .monthly, "#5D4037", symbol: "house.lodge.fill"),
        t("Revolut Premium", 7.99, .monthly, "#191C1F", domain: "revolut.com"),
        t("N26 You", 9.90, .monthly, "#48AC98", domain: "n26.com"),
        t("American Express", 12.50, .monthly, "#2E77BC", domain: "americanexpress.com"),
        t("Qonto", 9.00, .monthly, "#6643FF", domain: "qonto.com"),
        t("Boursorama Banque", 1.50, .monthly, "#FF6F00", domain: "boursorama.com"),
        t("MMA Assurance", 38.00, .monthly, "#00529B", domain: "mma.fr"),
        t("Ornikar Assurance", 42.00, .monthly, "#6C5CE7", domain: "ornikar.com"),
        t("MAIF", 34.50, .monthly, "#E2001A", domain: "maif.fr"),
        t("Macif", 31.00, .monthly, "#E2001A", domain: "macif.fr"),
        t("AXA Assurance", 55.00, .monthly, "#00008F", domain: "axa.fr"),
    ])

    // MARK: - Builders

    /// Applique une catégorie à tout un groupe (libellés de section déclaratifs).
    private static func section(_ category: SubscriptionCategory, _ items: [ServiceTemplate]) -> [ServiceTemplate] {
        items.map { var copy = $0; copy.category = category; return copy }
    }

    /// Fabrique compacte d'un modèle (la catégorie est posée par `section`).
    /// `domain` → logo de marque récupéré à distance ; sinon `symbol` (SF Symbol).
    private static func t(
        _ name: String,
        _ price: Decimal,
        _ cycle: BillingCycle,
        _ hex: String,
        domain: String? = nil,
        symbol: String = "creditcard.fill"
    ) -> ServiceTemplate {
        ServiceTemplate(
            name: name,
            category: .entertainment, // écrasé par section(_:_:)
            accentColorHex: hex,
            brandDomain: domain,
            iconSystemName: symbol,
            suggestedPrice: price,
            billingCycle: cycle
        )
    }
}
