import Foundation

/// API 서버 주소 설정.
///
/// 주소는 `Info.plist` 의 `JammyAPIBaseURL` 에서 읽는다. 값이 비어 있으면 앱은 Mock 데이터로 동작한다.
/// (서버 주소가 명세에 없어 임의로 정하지 않았다. 확정되면 Info.plist 또는 xcconfig 에 넣는다)
///
/// 개발 중에는 실행 환경변수 `JAMMY_API_BASE_URL` 로 덮어쓸 수 있다. (DEBUG 빌드만)
enum APIConfig {
    static var baseURL: URL? {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["JAMMY_API_BASE_URL"], let url = makeURL(override) {
            return url
        }
        #endif
        let value = Bundle.main.object(forInfoDictionaryKey: "JammyAPIBaseURL") as? String
        return value.flatMap { makeURL($0) }
    }

    private static func makeURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else { return nil }
        return url
    }
}
