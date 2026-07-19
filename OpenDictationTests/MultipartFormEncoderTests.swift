import Foundation
import Testing
@testable import OpenDictation

struct MultipartFormEncoderTests {
    @Test func contentTypeIncludesBoundary() {
        let encoder = MultipartFormEncoder(boundary: "test-boundary")
        #expect(encoder.contentType == "multipart/form-data; boundary=test-boundary")
    }

    @Test func encodesTextField() {
        let encoder = MultipartFormEncoder(boundary: "B")
        let body = String(decoding: encoder.encode([.field(name: "model", value: "whisper-1")]), as: UTF8.self)

        #expect(body == "--B\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\nwhisper-1\r\n--B--\r\n")
    }

    @Test func encodesFilePartWithContentType() {
        let encoder = MultipartFormEncoder(boundary: "B")
        let body = String(
            decoding: encoder.encode([
                .file(name: "file", filename: "audio.m4a", contentType: "audio/mp4", data: Data("AUDIO".utf8)),
            ]),
            as: UTF8.self
        )

        #expect(body.contains("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n"))
        #expect(body.contains("Content-Type: audio/mp4\r\n\r\nAUDIO\r\n"))
    }

    @Test func encodesMultiplePartsInOrderAndTerminates() throws {
        let encoder = MultipartFormEncoder(boundary: "B")
        let body = String(
            decoding: encoder.encode([
                .field(name: "a", value: "1"),
                .field(name: "b", value: "2"),
            ]),
            as: UTF8.self
        )

        let aIndex = try #require(body.range(of: "name=\"a\"")).lowerBound
        let bIndex = try #require(body.range(of: "name=\"b\"")).lowerBound
        #expect(aIndex < bIndex)
        #expect(body.hasSuffix("--B--\r\n"))
    }

    @Test func generatedBoundariesAreUnique() {
        #expect(MultipartFormEncoder().boundary != MultipartFormEncoder().boundary)
    }
}
