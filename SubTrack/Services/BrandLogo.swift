//
//  BrandLogo.swift
//  SubTrack
//
//  Construit les URLs de logos de marque à partir d'un domaine (ex.
//  "netflix.com"). Les logos ne sont PAS embarqués dans le bundle : ils sont
//  récupérés à la demande, ce qui évite de redistribuer des marques tierces
//  dans le dépôt (voir LICENSE).
//
//  Stratégie en cascade, par ordre de qualité décroissante :
//   1. Logo.dev — vrais logos couleur HD (nécessite un token gratuit) ;
//   2. favicon Google — fonctionne sans token, qualité moindre ;
//   3. (côté vue) repli monogramme si tout échoue.
//

import UIKit

enum BrandLogo {

    /// Token Logo.dev (publishable, `pk_…`), injecté dans l'Info.plist via
    /// `Config/Secrets.xcconfig`. Vide → on saute Logo.dev et on passe direct
    /// au favicon : l'app reste fonctionnelle sans configuration.
    static var logoDevToken: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "LOGODEV_TOKEN") as? String
        return raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// URLs candidates à tenter dans l'ordre pour un domaine donné, dimensionnées
    /// en pixels physiques (`size` en points × échelle écran).
    static func candidateURLs(domain: String, pointSize: CGFloat) -> [URL] {
        let clean = normalize(domain)
        guard !clean.isEmpty else { return [] }

        let px = max(64, Int(pointSize * UIScreen.main.scale))
        var urls: [URL] = []

        let token = logoDevToken
        if !token.isEmpty,
           var comps = URLComponents(string: "https://img.logo.dev/\(clean)") {
            comps.queryItems = [
                .init(name: "token", value: token),
                .init(name: "size", value: String(px)),
                .init(name: "format", value: "png"),
                .init(name: "retina", value: "true"),
            ]
            if let url = comps.url { urls.append(url) }
        }

        // Favicon Google : aucune clé requise, plafonné à 256 px.
        if let url = URL(string: "https://www.google.com/s2/favicons?domain=\(clean)&sz=\(min(px, 256))") {
            urls.append(url)
        }

        return urls
    }

    /// Nettoie un domaine saisi : retire le schéma, `www.` et un éventuel chemin.
    private static func normalize(_ domain: String) -> String {
        var d = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        d = d.replacingOccurrences(of: "https://", with: "")
        d = d.replacingOccurrences(of: "http://", with: "")
        if d.hasPrefix("www.") { d.removeFirst(4) }
        if let slash = d.firstIndex(of: "/") { d = String(d[..<slash]) }
        return d
    }
}

// MARK: - Téléchargement (cache disque + mémoire)

/// Récupère une image de logo, en s'appuyant sur le cache HTTP partagé pour ne
/// pas re-télécharger à chaque apparition d'une cellule.
enum BrandLogoFetcher {

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 8 << 20, diskCapacity: 64 << 20)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    /// Renvoie l'image si l'URL répond une vraie image exploitable, sinon `nil`
    /// (afin que l'appelant tente l'URL candidate suivante).
    static func fetch(_ url: URL) async -> UIImage? {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data),
                  image.size.width > 2 else { return nil }
            return image
        } catch {
            return nil
        }
    }
}
