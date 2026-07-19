import Foundation

/// Builds `multipart/form-data` request bodies (RFC 7578). Pure function of
/// its inputs so it can be tested byte-for-byte without any networking.
struct MultipartFormEncoder: Sendable {
    enum Part {
        case field(name: String, value: String)
        case file(name: String, filename: String, contentType: String, data: Data)
    }

    let boundary: String

    init(boundary: String = "opendictation-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    /// Value for the request's `Content-Type` header.
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    func encode(_ parts: [Part]) -> Data {
        var body = Data()
        for part in parts {
            body.append(text: "--\(boundary)\r\n")
            switch part {
            case .field(let name, let value):
                body.append(text: "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
                body.append(text: value)
            case .file(let name, let filename, let contentType, let data):
                body.append(text: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
                body.append(text: "Content-Type: \(contentType)\r\n\r\n")
                body.append(data)
            }
            body.append(text: "\r\n")
        }
        body.append(text: "--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func append(text: String) {
        append(Data(text.utf8))
    }
}
