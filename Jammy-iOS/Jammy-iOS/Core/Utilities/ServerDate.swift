import Foundation

/// 서버의 LocalDate("2026-10-12") / LocalDateTime("2026-10-14T20:00:00") 문자열 변환.
///
/// - LocalDate(여행 시작/종료일)는 달력 날짜일 뿐이라 기기 시간대로 해석한다.
/// - LocalDateTime(공개 일시, 일기 작성 시각)은 시간대가 없지만, 실제 서버가 **UTC 기준**으로 저장·비교한다.
///   (일기 작성 시각이 한국 시각보다 9시간 늦게 내려오고, 샘플 방의 공개 시각 11:00 은 한국 시각 20:00 이다)
///   그래서 보낼 때는 UTC 로 바꿔 보내고, 받을 때는 UTC 로 읽어 기기 시각으로 보여준다.
///   서버 시간대가 바뀌면 `serverTimeZone` 만 고치면 된다.
enum ServerDate {
    static let serverTimeZone = TimeZone(identifier: "UTC") ?? .gmt

    private static func makeFormatter(_ format: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }

    private static let dateFormatter = makeFormatter("yyyy-MM-dd", timeZone: .current)
    private static let dateTimeFormatter = makeFormatter("yyyy-MM-dd'T'HH:mm:ss", timeZone: serverTimeZone)
    private static let dateTimeFractionFormatter = makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", timeZone: serverTimeZone)

    static func date(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    static func dateTime(_ string: String) -> Date? {
        dateTimeFormatter.date(from: string) ?? dateTimeFractionFormatter.date(from: string)
    }

    static func string(fromDate date: Date) -> String { dateFormatter.string(from: date) }

    static func string(fromDateTime date: Date) -> String { dateTimeFormatter.string(from: date) }
}
