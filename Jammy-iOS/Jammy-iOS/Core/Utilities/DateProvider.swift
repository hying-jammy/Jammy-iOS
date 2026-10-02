import Foundation

/// 현재 시각을 주입하기 위한 추상화.
/// 타임캡슐 공개 여부는 서버 시각이 원칙이므로, 지금은 시스템 시각을 쓰되 테스트/교체가 가능하게 감싼다.
nonisolated protocol DateProvider {
    var now: Date { get }
}

nonisolated struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
}
