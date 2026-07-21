import Foundation
import Testing
@testable import OpenDictation

/// Serialized because the URLProtocol stub's handler is shared static state.
@Suite(.serialized)
struct OpenAITranscriptionProviderTests {
    private let provider = OpenAITranscriptionProvider(session: StubURLProtocol.session())
    private let configuration = TranscriptionConfiguration(apiKey: "sk-test", model: "gpt-4o-transcribe")

    // MARK: - Success

    @Test func successfulResponseProducesTranscript() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 200, body: #"{"text": "Hello, world."}"#)

        let transcript = try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)

        #expect(transcript.text == "Hello, world.")
        #expect(transcript.providerID == "openai")
        #expect(transcript.model == "gpt-4o-transcribe")
    }

    @Test func requestCarriesAuthorizationAndMultipartBody() async throws {
        let audioURL = try makeAudioFile()
        nonisolated(unsafe) var captured: URLRequest?
        StubURLProtocol.requestHandler = { request in
            captured = request
            return (Self.httpResponse(status: 200), Data(#"{"text": "ok"}"#.utf8))
        }

        _ = try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)

        let request = try #require(captured)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
    }

    @Test func requestSendsModelAndDeterministicTemperature() async throws {
        let audioURL = try makeAudioFile()
        nonisolated(unsafe) var capturedBody: Data?
        StubURLProtocol.requestHandler = { request in
            // URLProtocol exposes the streamed body via httpBodyStream.
            capturedBody = request.readHTTPBody()
            return (Self.httpResponse(status: 200), Data(#"{"text": "ok"}"#.utf8))
        }

        _ = try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)

        let body = String(decoding: try #require(capturedBody), as: UTF8.self)
        #expect(body.contains(#"name="model""#))
        #expect(body.contains("gpt-4o-transcribe"))
        #expect(body.contains(#"name="temperature""#))
        #expect(body.contains("0.0"))
    }

    // MARK: - Typed failures

    @Test func emptyAPIKeyFailsWithoutNetworkCall() async throws {
        let audioURL = try makeAudioFile()
        let config = TranscriptionConfiguration(apiKey: "  ", model: "whisper-1")

        await expectFailure(.missingAPIKey) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: config)
        }
    }

    @Test func missingAudioFileIsUnreadable() async {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID()).m4a")

        await expectFailure(.audioFileUnreadable) {
            try await provider.transcribe(audioFileURL: missing, configuration: configuration)
        }
    }

    @Test func unauthorizedMeansInvalidAPIKey() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 401, body: #"{"error": {"message": "Incorrect API key provided"}}"#)

        await expectFailure(.invalidAPIKey) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func rateLimitedCarriesRetryAfter() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 429, body: #"{"error": {"message": "Rate limit reached"}}"#, headers: ["Retry-After": "7"])

        await expectFailure(.rateLimited(retryAfter: 7)) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func badRequestAboutFormatIsUnsupportedAudio() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 400, body: #"{"error": {"message": "Invalid file format."}}"#)

        await expectFailure(.unsupportedAudio) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func serverErrorIsTyped() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 503, body: "")

        await expectFailure(.serverError(statusCode: 503)) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func offlineIsNetworkUnavailable() async throws {
        let audioURL = try makeAudioFile()
        StubURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        await expectFailure(.networkUnavailable) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func timeoutIsTyped() async throws {
        let audioURL = try makeAudioFile()
        StubURLProtocol.requestHandler = { _ in throw URLError(.timedOut) }

        await expectFailure(.requestTimedOut) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func otherClientErrorSurfacesAPIMessage() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 402, body: #"{"error": {"message": "You exceeded your current quota."}}"#)

        await expectFailure(.providerError(message: "You exceeded your current quota.")) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    @Test func malformedSuccessBodyIsProviderError() async throws {
        let audioURL = try makeAudioFile()
        stub(status: 200, body: #"{"no_text": true}"#)

        await expectFailure(.providerError(message: "The transcription service returned an unreadable response.")) {
            try await provider.transcribe(audioFileURL: audioURL, configuration: configuration)
        }
    }

    // MARK: - Helpers

    private func makeAudioFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenDictationTests-\(UUID().uuidString).m4a")
        try Data("not-really-audio".utf8).write(to: url)
        return url
    }

    private func stub(status: Int, body: String, headers: [String: String] = [:]) {
        StubURLProtocol.requestHandler = { _ in
            (Self.httpResponse(status: status, headers: headers), Data(body.utf8))
        }
    }

    private static func httpResponse(status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
    }

    private func expectFailure(_ expected: AppError, _ body: () async throws -> Transcript) async {
        do {
            _ = try await body()
            Issue.record("Expected \(expected) but the call succeeded")
        } catch let error as AppError {
            #expect(error == expected)
        } catch {
            Issue.record("Expected AppError.\(expected) but got \(error)")
        }
    }
}
