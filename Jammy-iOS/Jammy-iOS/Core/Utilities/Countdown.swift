import Foundation

/// 타임캡슐 공개까지 남은 시간. 순수 값 타입이라 단위 테스트가 쉽다.
struct Countdown: Equatable {
    let days: Int
    let hours: Int
    let minutes: Int

    init(from now: Date, to target: Date) {
        let remaining = max(0, Int(target.timeIntervalSince(now)))
        days = remaining / 86_400
        hours = (remaining % 86_400) / 3_600
        minutes = (remaining % 3_600) / 60
    }

    var isFinished: Bool { days == 0 && hours == 0 && minutes == 0 }

    /// "D-2" / "D-DAY"
    var dDayText: String { days > 0 ? "D-\(days)" : "D-DAY" }
}
