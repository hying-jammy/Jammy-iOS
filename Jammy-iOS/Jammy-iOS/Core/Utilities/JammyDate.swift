import Foundation

/// 화면에 보여주는 날짜/시간 문자열 포맷 모음 (예: "10.14 (화)", "오후 8:00").
enum JammyDate {
    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter
    }

    private static let monthDayFormatter = makeFormatter("M.d")
    private static let weekdayFormatter = makeFormatter("M.d (E)")
    private static let timeFormatter = makeFormatter("a h:mm")
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .full
        return formatter
    }()

    /// "10.12"
    static func monthDay(_ date: Date) -> String { monthDayFormatter.string(from: date) }

    /// "10.14 (화)"
    static func monthDayWeekday(_ date: Date) -> String { weekdayFormatter.string(from: date) }

    /// "오후 8:00"
    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }

    /// "10.12 – 10.14" (같은 날이면 "10.12")
    static func range(_ start: Date, _ end: Date) -> String {
        if Calendar.current.isDate(start, inSameDayAs: end) { return monthDay(start) }
        return "\(monthDay(start)) – \(monthDay(end))"
    }

    /// "5분 전", "1시간 전"
    static func relative(_ date: Date, to now: Date) -> String {
        if now.timeIntervalSince(date) < 60 { return "방금 전" }
        return relativeFormatter.localizedString(for: date, relativeTo: now)
    }
}
