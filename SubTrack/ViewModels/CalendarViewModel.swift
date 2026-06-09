//
//  CalendarViewModel.swift
//  SubTrack
//
//  Logique de la vue calendrier : grille du mois affiché, prélèvements par
//  jour, totaux. Données injectées via `apply(subscriptions:)` (DRY avec le
//  reste de l'app). Aucun accès base ici.
//

import Foundation
import Observation

@Observable
@MainActor
final class CalendarViewModel {

    /// Premier jour du mois affiché (normalisé).
    private(set) var displayedMonth: Date
    /// Jour sélectionné (normalisé au début de journée).
    var selectedDay: Date

    private var subscriptions: [Subscription] = []
    private var byDay: [Date: [Subscription]] = [:]

    private let calendar = Calendar.current

    init(reference: Date = .now) {
        let cal = Calendar.current
        displayedMonth = cal.date(from: cal.dateComponents([.year, .month], from: reference)) ?? cal.startOfDay(for: reference)
        selectedDay = cal.startOfDay(for: reference)
    }

    // MARK: Données

    func apply(subscriptions: [Subscription]) {
        self.subscriptions = subscriptions
        recompute()
    }

    private func recompute() {
        byDay = BillingSchedule.occurrencesByDay(subscriptions, in: monthInterval)
    }

    // MARK: Navigation

    var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year().locale(AppLocale.current))
    }

    func goToPreviousMonth() { shiftMonth(by: -1) }
    func goToNextMonth() { shiftMonth(by: 1) }

    func goToToday() {
        let comps = calendar.dateComponents([.year, .month], from: .now)
        displayedMonth = calendar.date(from: comps) ?? displayedMonth
        selectedDay = calendar.startOfDay(for: .now)
        recompute()
    }

    private func shiftMonth(by delta: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        displayedMonth = newMonth
        recompute()
    }

    // MARK: Grille

    /// Intervalle couvrant le mois affiché (du 1er au dernier jour, fin de journée).
    private var monthInterval: DateInterval {
        let start = displayedMonth
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        return DateInterval(start: start, end: endOfDay)
    }

    /// Les 42 jours (6 semaines) de la grille, alignés sur le premier jour de
    /// semaine de la locale (lundi en France).
    var gridDays: [Date] {
        let firstOfMonth = displayedMonth
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: firstOfMonth) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    /// En-têtes des jours de la semaine (« lun », « mar »…), ordonnés par locale
    /// et localisés selon la langue choisie.
    var weekdaySymbols: [String] {
        var localizedCalendar = calendar
        localizedCalendar.locale = AppLocale.current
        let symbols = localizedCalendar.shortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    // MARK: Requêtes par jour

    func isInDisplayedMonth(_ day: Date) -> Bool {
        calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
    }

    func isToday(_ day: Date) -> Bool { calendar.isDateInToday(day) }

    func isSelected(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDay)
    }

    func subscriptions(on day: Date) -> [Subscription] {
        (byDay[calendar.startOfDay(for: day)] ?? []).sorted { $0.effectivePrice > $1.effectivePrice }
    }

    func hasBillings(on day: Date) -> Bool {
        byDay[calendar.startOfDay(for: day)]?.isEmpty == false
    }

    /// Total prélevé un jour donné (somme des prix effectifs).
    func total(on day: Date) -> Decimal {
        subscriptions(on: day).reduce(0) { $0 + $1.effectivePrice }
    }

    /// Total prélevé sur l'ensemble du mois affiché.
    var monthTotal: Decimal {
        byDay.values.flatMap { $0 }.reduce(0) { $0 + $1.effectivePrice }
    }

    func select(_ day: Date) {
        selectedDay = calendar.startOfDay(for: day)
    }
}
