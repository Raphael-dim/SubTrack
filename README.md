# SubTrack

Application iOS de suivi d'abonnements, écrite en **SwiftUI + SwiftData**.
Stockage **100 % local** (aucune synchronisation iCloud, aucun backend, aucune
collecte de données).

## Fonctionnalités

- Liste des abonnements avec total mensuel/annuel
- Catalogue de services pré-remplis avec autocomplétion (Netflix, Spotify, banques…)
- Vue calendrier des prochains prélèvements
- Statistiques par catégorie (graphique en anneau)
- Rappels de prélèvement (notifications locales)
- Thème clair / sombre, design « glass »

## Prérequis

- Xcode 16+
- iOS 18.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Démarrage

```bash
xcodegen generate      # régénère SubTrack.xcodeproj depuis project.yml
open SubTrack.xcodeproj
```

Sélectionne ton équipe de signature (Signing & Capabilities) dans Xcode avant
de lancer sur un appareil physique — aucune équipe n'est versionnée dans ce dépôt.

### Logos de marque (optionnel)

Les logos ne sont **pas embarqués** : ils sont récupérés à la demande à partir
du domaine de chaque service. Par défaut l'app utilise les favicons (gratuit,
sans clé) puis retombe sur un monogramme coloré.

Pour des logos couleur HD, crée un token gratuit sur [logo.dev](https://www.logo.dev),
puis crée un fichier **local** (non versionné) `Config/Secrets.local.xcconfig` :

```
LOGODEV_TOKEN = pk_ta_cle_publishable
```

Ce fichier est ignoré par git (voir `.gitignore`) : ta clé reste sur ta machine.
Sans token, l'app fonctionne quand même (favicons puis monogramme).

## Architecture

- `Models/` — modèles SwiftData (`Subscription`, `BillingCycle`, catégories…)
- `Services/` — logique métier (catalogue, échéancier, métriques, notifications)
- `ViewModels/` — état des écrans
- `Views/` — écrans SwiftUI (liste, détail, éditeur, calendrier, stats, réglages)
- `DesignSystem/` — thème, composants « glass », haptique

## ⚠️ Logos de marques

Les logos affichés sont des marques déposées appartenant à leurs propriétaires
respectifs ; ils sont récupérés à distance et ne sont **pas redistribués** dans
ce dépôt. Leur affichage sert uniquement à identifier les services. Voir
[NOTICE.md](NOTICE.md) pour les détails.

## Licence

Le code source est distribué sous licence MIT — voir [LICENSE](LICENSE).
Les logos de marque ne sont pas couverts par cette licence — voir [NOTICE.md](NOTICE.md).
