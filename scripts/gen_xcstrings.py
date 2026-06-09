#!/usr/bin/env python3
"""Génère Localizable.xcstrings (FR source + EN/ES/DE) pour SubTrack.

La clé de chaque entrée EST la chaîne source française (telle que passée à
`L.t(...)`). On fournit aussi l'entrée fr explicite (= source) pour garantir la
génération de fr.lproj, afin que le choix explicite « Français » fonctionne même
sur un appareil non francophone.
"""
import json
from pathlib import Path

# french_key -> (en, es, de)
T = {
    # Onglets / titres
    "Abonnements": ("Subscriptions", "Suscripciones", "Abos"),
    "Calendrier": ("Calendar", "Calendario", "Kalender"),
    "Statistiques": ("Statistics", "Estadísticas", "Statistiken"),
    "Réglages": ("Settings", "Ajustes", "Einstellungen"),

    # Réglages
    "Apparence": ("Appearance", "Apariencia", "Darstellung"),
    "Thème": ("Theme", "Tema", "Design"),
    "Préférences": ("Preferences", "Preferencias", "Präferenzen"),
    "Langue": ("Language", "Idioma", "Sprache"),
    "Devise": ("Currency", "Moneda", "Währung"),
    "La devise s'applique aux totaux. La langue ajuste le format des dates et des montants.": (
        "The currency applies to totals. The language adjusts the format of dates and amounts.",
        "La moneda se aplica a los totales. El idioma ajusta el formato de fechas e importes.",
        "Die Währung gilt für die Summen. Die Sprache passt das Format von Datum und Beträgen an.",
    ),
    "Rappels de prélèvement": ("Payment reminders", "Recordatorios de cobro", "Zahlungserinnerungen"),
    "Me prévenir": ("Notify me", "Avisarme", "Erinnern"),
    "Notifications": ("Notifications", "Notificaciones", "Mitteilungen"),
    "Rappels 100 % locaux, avant chaque prélèvement et chaque fin d'essai. Aucune donnée n'est envoyée.": (
        "100% local reminders, before each payment and each trial ending. No data is sent.",
        "Recordatorios 100 % locales, antes de cada cobro y de cada fin de prueba. No se envía ningún dato.",
        "100 % lokale Erinnerungen, vor jeder Abbuchung und jedem Testende. Es werden keine Daten gesendet.",
    ),
    "Le jour même": ("On the day", "El mismo día", "Am selben Tag"),
    "1 jour avant": ("1 day before", "1 día antes", "1 Tag vorher"),
    "%d jours avant": ("%d days before", "%d días antes", "%d Tage vorher"),
    "Version": ("Version", "Versión", "Version"),
    "100 % local — aucune donnée ne quitte votre appareil.": (
        "100% local — no data leaves your device.",
        "100 % local: ningún dato sale de tu dispositivo.",
        "100 % lokal – keine Daten verlassen dein Gerät.",
    ),
    "À propos": ("About", "Acerca de", "Über"),
    "Seed au démarrage": ("Seed on launch", "Cargar datos al iniciar", "Beim Start befüllen"),
    "Recharger le catalogue de démo": ("Reload demo catalog", "Recargar el catálogo de demo", "Demo-Katalog neu laden"),
    "Tout effacer": ("Erase all", "Borrar todo", "Alles löschen"),
    "Développeur": ("Developer", "Desarrollador", "Entwickler"),
    "Section visible uniquement en build de développement (DEBUG).": (
        "Section visible only in development builds (DEBUG).",
        "Sección visible solo en compilaciones de desarrollo (DEBUG).",
        "Bereich nur in Entwicklungs-Builds sichtbar (DEBUG).",
    ),

    # Apparence
    "Système": ("System", "Sistema", "System"),
    "Clair": ("Light", "Claro", "Hell"),
    "Sombre": ("Dark", "Oscuro", "Dunkel"),

    # Devises
    "Euro (€)": ("Euro (€)", "Euro (€)", "Euro (€)"),
    "Dollar US ($)": ("US Dollar ($)", "Dólar EE. UU. ($)", "US-Dollar ($)"),
    "Livre sterling (£)": ("Pound sterling (£)", "Libra esterlina (£)", "Pfund Sterling (£)"),
    "Franc suisse (CHF)": ("Swiss franc (CHF)", "Franco suizo (CHF)", "Schweizer Franken (CHF)"),
    "Dollar canadien ($ CA)": ("Canadian dollar (CA$)", "Dólar canadiense ($ CA)", "Kanadischer Dollar (CA$)"),
    "Yen (¥)": ("Yen (¥)", "Yen (¥)", "Yen (¥)"),

    # Périodicités
    "Hebdomadaire": ("Weekly", "Semanal", "Wöchentlich"),
    "Mensuel": ("Monthly", "Mensual", "Monatlich"),
    "Trimestriel": ("Quarterly", "Trimestral", "Vierteljährlich"),
    "Annuel": ("Yearly", "Anual", "Jährlich"),

    # Catégories
    "Divertissement": ("Entertainment", "Entretenimiento", "Unterhaltung"),
    "Productivité / Tech": ("Productivity / Tech", "Productividad / Tec.", "Produktivität / Tech"),
    "Vie quotidienne": ("Daily life", "Vida diaria", "Alltag"),
    "Assurances / Banques": ("Insurance / Banking", "Seguros / Bancos", "Versicherung / Bank"),

    # Tri
    "Prochain prélèvement": ("Next payment", "Próximo cobro", "Nächste Abbuchung"),
    "Prix décroissant": ("Price descending", "Precio descendente", "Preis absteigend"),
    "Nom (A→Z)": ("Name (A→Z)", "Nombre (A→Z)", "Name (A→Z)"),

    # Éditeur — titres
    "Nouvel abonnement": ("New subscription", "Nueva suscripción", "Neues Abo"),
    "Modifier": ("Edit", "Editar", "Bearbeiten"),

    # Liste
    "Rechercher un abonnement": ("Search for a subscription", "Buscar una suscripción", "Abo suchen"),
    "Mettre en pause": ("Pause", "Pausar", "Pausieren"),
    "Réactiver": ("Resume", "Reactivar", "Fortsetzen"),
    "Supprimer": ("Delete", "Eliminar", "Löschen"),
    "Aucun abonnement": ("No subscriptions", "Sin suscripciones", "Keine Abos"),
    "Ajoutez votre premier abonnement pour suivre vos dépenses.": (
        "Add your first subscription to track your spending.",
        "Añade tu primera suscripción para controlar tus gastos.",
        "Füge dein erstes Abo hinzu, um deine Ausgaben zu verfolgen.",
    ),
    "Ajouter": ("Add", "Añadir", "Hinzufügen"),
    "Ajouter un abonnement": ("Add a subscription", "Añadir una suscripción", "Abo hinzufügen"),
    "Trier par": ("Sort by", "Ordenar por", "Sortieren nach"),
    "Trier": ("Sort", "Ordenar", "Sortieren"),
    "Tout": ("All", "Todo", "Alle"),

    # Ligne
    "Essai gratuit · %@": ("Free trial · %@", "Prueba gratis · %@", "Kostenlose Testphase · %@"),
    "· %@": ("· %@", "· %@", "· %@"),
    "%@ · %@": ("%@ · %@", "%@ · %@", "%@ · %@"),
    "Essai": ("Trial", "Prueba", "Test"),
    "Promo": ("Promo", "Promo", "Aktion"),
    "En retard": ("Overdue", "Atrasado", "Überfällig"),
    "Aujourd'hui": ("Today", "Hoy", "Heute"),
    "Demain": ("Tomorrow", "Mañana", "Morgen"),
    "Dans %d j": ("In %d d", "En %d d", "In %d T"),
    ", en pause": (", paused", ", en pausa", ", pausiert"),
    "%@, %@ %@": ("%@, %@ %@", "%@, %@ %@", "%@, %@ %@"),

    # En-tête total
    "Dépense mensuelle": ("Monthly spending", "Gasto mensual", "Monatliche Ausgaben"),
    "%@ / an": ("%@ / yr", "%@ / año", "%@ / Jahr"),
    "%d actifs": ("%d active", "%d activos", "%d aktiv"),

    # Détail
    "Supprimer « %@ » ?": ("Delete “%@”?", "¿Eliminar «%@»?", "„%@“ löschen?"),
    "Cette action est définitive.": ("This action is permanent.", "Esta acción es definitiva.", "Diese Aktion ist endgültig."),
    "Annuler": ("Cancel", "Cancelar", "Abbrechen"),
    "par %@": ("per %@", "por %@", "pro %@"),
    "Soit / mois": ("Per month", "Al mes", "Pro Monat"),
    "Soit / an": ("Per year", "Al año", "Pro Jahr"),
    "Statut": ("Status", "Estado", "Status"),
    "Actif": ("Active", "Activo", "Aktiv"),
    "En pause": ("Paused", "En pausa", "Pausiert"),
    "jusqu'au %@": ("until %@", "hasta el %@", "bis %@"),
    "dans %d j": ("in %d d", "en %d d", "in %d T"),
    "Rappels": ("Reminders", "Recordatorios", "Erinnerungen"),
    "Activés": ("On", "Activados", "Ein"),
    "Désactivés": ("Off", "Desactivados", "Aus"),
    "en retard": ("overdue", "atrasado", "überfällig"),
    "aujourd'hui": ("today", "hoy", "heute"),
    "demain": ("tomorrow", "mañana", "morgen"),
    "dans %d jours": ("in %d days", "en %d días", "in %d Tagen"),
    "Notes": ("Notes", "Notas", "Notizen"),
    "Prix promotionnel": ("Promotional price", "Precio promocional", "Aktionspreis"),
    "Essai gratuit": ("Free trial", "Prueba gratis", "Kostenlose Testphase"),
    "Souscrit le": ("Subscribed on", "Suscrito el", "Abonniert am"),

    # Stats
    "Aucune donnée": ("No data", "Sin datos", "Keine Daten"),
    "Ajoutez des abonnements actifs pour voir vos statistiques.": (
        "Add active subscriptions to see your statistics.",
        "Añade suscripciones activas para ver tus estadísticas.",
        "Füge aktive Abos hinzu, um deine Statistiken zu sehen.",
    ),
    "Par mois": ("Per month", "Al mes", "Pro Monat"),
    "Par an": ("Per year", "Al año", "Pro Jahr"),
    "Répartition par catégorie": ("Breakdown by category", "Desglose por categoría", "Aufteilung nach Kategorie"),
    "%d abonnements": ("%d subscriptions", "%d suscripciones", "%d Abos"),
    "%d abonnement": ("%d subscription", "%d suscripción", "%d Abo"),
    "Poste le plus coûteux": ("Most expensive item", "Gasto más caro", "Teuerster Posten"),
    "%@ / mois": ("%@ / mo", "%@ / mes", "%@ / Mon."),

    # Donut
    "Répartition des dépenses mensuelles par catégorie": (
        "Monthly spending breakdown by category",
        "Desglose del gasto mensual por categoría",
        "Aufteilung der monatlichen Ausgaben nach Kategorie",
    ),
    "par mois": ("per month", "al mes", "pro Monat"),

    # Calendrier
    "Total du mois": ("Month total", "Total del mes", "Monatssumme"),
    "Aucun prélèvement ce jour-là.": ("No payments on this day.", "Sin cobros ese día.", "Keine Abbuchungen an diesem Tag."),

    # Éditeur — champs
    "Enregistrer": ("Save", "Guardar", "Sichern"),
    "Détails": ("Details", "Detalles", "Details"),
    "Nom": ("Name", "Nombre", "Name"),
    "Prix": ("Price", "Precio", "Preis"),
    "Catégorie": ("Category", "Categoría", "Kategorie"),
    "Facturation": ("Billing", "Facturación", "Abrechnung"),
    "Périodicité": ("Frequency", "Periodicidad", "Intervall"),
    "Début de l'abonnement": ("Subscription start", "Inicio de la suscripción", "Abo-Beginn"),
    "Fin de l'essai": ("Trial end", "Fin de la prueba", "Testende"),
    "Prix promo": ("Promo price", "Precio promo", "Aktionspreis"),
    "Date de fin de promo": ("Promo end date", "Fecha de fin de promo", "Enddatum der Aktion"),
    "Fin de la promo": ("Promo end", "Fin de la promo", "Aktionsende"),
    "Remise": ("Discount", "Descuento", "Rabatt"),
    "Pendant l'essai, le coût compté est de 0 €.": (
        "During the trial, the counted cost is 0 €.",
        "Durante la prueba, el coste contado es de 0 €.",
        "Während der Testphase werden 0 € berechnet.",
    ),
    "En période d'essai": ("In trial period", "En periodo de prueba", "In Testphase"),
    "Me rappeler les échéances": ("Remind me of due dates", "Recordarme los vencimientos", "An Fälligkeiten erinnern"),
    "Le rappel global et son délai se règlent dans Réglages.": (
        "The global reminder and its lead time are set in Settings.",
        "El recordatorio global y su antelación se configuran en Ajustes.",
        "Die globale Erinnerung und die Vorlaufzeit werden in den Einstellungen festgelegt.",
    ),
    "Couleur": ("Color", "Color", "Farbe"),
    "Icône": ("Icon", "Icono", "Symbol"),
    "Abonnement actif": ("Active subscription", "Suscripción activa", "Aktives Abo"),
    "Désactivez pour mettre en pause sans supprimer l'historique.": (
        "Turn off to pause without deleting the history.",
        "Desactiva para pausar sin eliminar el historial.",
        "Deaktivieren, um zu pausieren, ohne den Verlauf zu löschen.",
    ),

    # Notifications
    "Prélèvement à venir": ("Upcoming payment", "Cobro próximo", "Bevorstehende Abbuchung"),
    "%@ — %@ le %@": ("%@ — %@ on %@", "%@ — %@ el %@", "%@ — %@ am %@"),
    "Fin d'essai gratuit": ("Free trial ending", "Fin de prueba gratis", "Ende der Testphase"),
    "%@ : l'essai se termine le %@. Pensez à résilier si besoin.": (
        "%@: the trial ends on %@. Remember to cancel if needed.",
        "%@: la prueba termina el %@. Recuerda cancelar si lo necesitas.",
        "%@: Die Testphase endet am %@. Denk daran, bei Bedarf zu kündigen.",
    ),
}


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


strings = {}
for fr, (en, es, de) in T.items():
    strings[fr] = {
        "localizations": {
            "fr": unit(fr),
            "en": unit(en),
            "es": unit(es),
            "de": unit(de),
        }
    }

catalog = {
    "sourceLanguage": "fr",
    "strings": strings,
    "version": "1.0",
}

out = Path("SubTrack/Resources/Localizable.xcstrings")
out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {out} with {len(strings)} keys")
