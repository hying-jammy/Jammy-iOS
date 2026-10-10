import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

/// multipart/form-data 본문 (글 업로드용).
struct MultipartForm {
    struct File {
        let name: String
        let filename: String
        let mimeType: String
        let data: Data
    }

    var fields: [String: String] = [:]
    var files: [File] = []
    let boundary = "Boundary-\(UUID().uuidString)"

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    var body: Data {
        var data = Data()
        func append(_ string: String) { data.append(Data(string.utf8)) }
        for (key, value) in fields.sorted(by: { $0.key < $1.key }) {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            append("\(value)\r\n")
        }
        for file in files {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.filename)\"\r\n")
            append("Content-Type: \(file.mimeType)\r\n\r\n")
            data.append(file.data)
            append("\r\n")
        }
        append("--\(boundary)--\r\n")
        return data
    }
}

/// 요청 한 건의 정의. 경로는 이미 퍼센트 인코딩된 상태여야 한다.
struct APIRequest {
    var method: HTTPMethod
    var path: String
    var jsonBody: Data?
    var multipart: MultipartForm?

    init(method: HTTPMethod, path: String, jsonBody: Data? = nil, multipart: MultipartForm? = nil) {
        self.method = method
        self.path = path
        self.jsonBody = jsonBody
        self.multipart = multipart
    }

    /// Encodable 본문을 JSON 으로 담는다.
    static func json<Body: Encodable>(_ method: HTTPMethod, _ path: String, body: Body) throws -> APIRequest {
        APIRequest(method: method, path: path, jsonBody: try JSONEncoder().encode(body))
    }
}
