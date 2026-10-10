import Foundation

/// 서버 공통 응답 포맷: `{ isSuccess, code, message, result }`
struct APIEnvelope<Result: Decodable>: Decodable {
    let isSuccess: Bool
    let code: Int
    let message: String?
    let result: Result?
}

/// 결과 값이 필요 없는 응답을 위한 빈 타입.
struct EmptyResult: Decodable {}

/// 실패 응답 본문에서 메시지만 꺼낸다.
private struct APIErrorBody: Decodable {
    let message: String?
}

/// URLSession 기반 API 클라이언트.
/// HTTP 상태 코드를 `AppError` 로 변환해 던진다. 상황별 의미(초대 코드 오류 등)는 Repository 에서 다시 해석한다.
struct APIClient {
    let baseURL: URL
    var session: URLSession = .shared
    var decoder: JSONDecoder = JSONDecoder()

    /// 응답의 `result` 를 디코딩해 돌려준다.
    func send<Result: Decodable>(_ request: APIRequest, as type: Result.Type = Result.self) async throws -> Result {
        let (data, response) = try await perform(request)
        guard let http = response as? HTTPURLResponse else { throw AppError.network }

        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(for: http.statusCode, data: data)
        }

        do {
            let envelope = try decoder.decode(APIEnvelope<Result>.self, from: data)
            guard envelope.isSuccess else { throw Self.error(for: envelope.code, message: envelope.message) }
            if let result = envelope.result { return result }
            if Result.self == EmptyResult.self, let empty = EmptyResult() as? Result { return empty }
            throw AppError.decoding
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.decoding
        }
    }

    /// 응답 `result` 를 쓰지 않는 요청.
    func sendIgnoringResult(_ request: APIRequest) async throws {
        let (data, response) = try await perform(request)
        guard let http = response as? HTTPURLResponse else { throw AppError.network }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(for: http.statusCode, data: data)
        }
        if let envelope = try? decoder.decode(APIEnvelope<EmptyResult>.self, from: data), !envelope.isSuccess {
            throw Self.error(for: envelope.code, message: envelope.message)
        }
    }

    // MARK: - Private

    private func perform(_ request: APIRequest) async throws -> (Data, URLResponse) {
        let urlRequest = try makeURLRequest(request)
        do {
            return try await session.data(for: urlRequest)
        } catch {
            throw AppError(error)
        }
    }

    private func makeURLRequest(_ request: APIRequest) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw AppError.network
        }
        let basePath = components.percentEncodedPath.hasSuffix("/")
            ? String(components.percentEncodedPath.dropLast())
            : components.percentEncodedPath
        components.percentEncodedPath = basePath + request.path
        guard let url = components.url else { throw AppError.network }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = 20
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let multipart = request.multipart {
            urlRequest.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = multipart.body
        } else if let jsonBody = request.jsonBody {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonBody
        }
        return urlRequest
    }

    private static func error(for status: Int, data: Data) -> AppError {
        let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.message
        return error(for: status, message: message)
    }

    private static func error(for status: Int, message: String?) -> AppError {
        switch status {
        case 400: .badRequest(message)
        case 401: .invalidCredentials
        case 403: .forbidden(message)
        case 404: .notFound
        case 409: .conflict(message)
        case 500...: .server(message)
        default: .unknown(message ?? "요청에 실패했어요. (\(status))")
        }
    }
}
