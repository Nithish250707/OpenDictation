import AVFoundation
import Foundation

/// Transcribes audio with OpenAI's speech-to-text API
/// (`POST /v1/audio/transcriptions`, multipart/form-data).
struct OpenAITranscriptionProvider: TranscriptionProvider {
    static let defaultModel = "gpt-4o-transcribe"
    /// Models known to work with this endpoint; Settings surfaces these.
    static let supportedModels = ["gpt-4o-transcribe", "gpt-4o-mini-transcribe", "whisper-1"]

    let id = "openai"
    let displayName = "OpenAI"

    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let session: URLSession
    private let requestTimeout: TimeInterval = 60

    /// - Parameter session: injectable for tests (URLProtocol stubs).
    init(session: URLSession = .shared) {
        self.session = session
    }

    func transcribe(audioFileURL: URL, configuration: TranscriptionConfiguration) async throws -> Transcript {
        let trimmedKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw AppError.missingAPIKey }

        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            throw AppError.audioFileUnreadable
        }

        let request = makeRequest(
            audioData: audioData,
            filename: audioFileURL.lastPathComponent,
            apiKey: trimmedKey,
            configuration: configuration
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw Self.map(urlError)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.providerError(message: "Unexpected response from the transcription service.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw Self.map(statusCode: http.statusCode, body: data, response: http)
        }

        guard let decoded = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) else {
            throw AppError.providerError(message: "The transcription service returned an unreadable response.")
        }

        return Transcript(
            text: decoded.text,
            duration: await Self.audioDuration(of: audioFileURL),
            providerID: id,
            model: configuration.model,
            createdAt: .now
        )
    }

    private func makeRequest(
        audioData: Data,
        filename: String,
        apiKey: String,
        configuration: TranscriptionConfiguration
    ) -> URLRequest {
        let encoder = MultipartFormEncoder()
        var parts: [MultipartFormEncoder.Part] = [
            .field(name: "model", value: configuration.model),
            .field(name: "response_format", value: "json"),
            .file(name: "file", filename: filename, contentType: "audio/mp4", data: audioData),
        ]
        if let language = configuration.language {
            parts.insert(.field(name: "language", value: language), at: 2)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(encoder.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = encoder.encode(parts)
        return request
    }

    // MARK: - Error mapping

    private static func map(_ error: URLError) -> AppError {
        switch error.code {
        case .timedOut:
            .requestTimedOut
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
             .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            .networkUnavailable
        default:
            .providerError(message: error.localizedDescription)
        }
    }

    private static func map(statusCode: Int, body: Data, response: HTTPURLResponse) -> AppError {
        let apiMessage = (try? JSONDecoder().decode(APIErrorResponse.self, from: body))?.error.message

        switch statusCode {
        case 401, 403:
            return .invalidAPIKey
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            return .rateLimited(retryAfter: retryAfter)
        case 415:
            return .unsupportedAudio
        case 400 where apiMessage?.localizedCaseInsensitiveContains("format") == true
            || apiMessage?.localizedCaseInsensitiveContains("file") == true:
            return .unsupportedAudio
        case 500...:
            return .serverError(statusCode: statusCode)
        default:
            return .providerError(message: apiMessage ?? "The transcription request failed (HTTP \(statusCode)).")
        }
    }

    /// Reads the clip length from the audio file itself, so `Transcript`
    /// carries a duration regardless of which model the API used (only
    /// whisper-1 reports duration in its response).
    private static func audioDuration(of url: URL) async -> TimeInterval {
        guard let duration = try? await AVURLAsset(url: url).load(.duration) else { return 0 }
        let seconds = duration.seconds
        return seconds.isFinite ? seconds : 0
    }
}

// MARK: - Wire formats

private struct TranscriptionResponse: Decodable {
    let text: String
}

private struct APIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}
