import AVFoundation

/// `AVAudioRecorder`-backed implementation of `AudioRecording`.
///
/// Records mono AAC (.m4a) at 16 kHz into the user's temporary directory. That
/// sample rate is exactly what speech-to-text models operate on internally, so
/// it costs no accuracy while making the file ~3× smaller than CD-rate audio —
/// a smaller upload is a faster transcription. The clip is never persisted
/// anywhere permanent. Metering is enabled so the UI can render a live waveform.
@MainActor
final class AVAudioRecordingService: AudioRecording {
    private var recorder: AVAudioRecorder?

    var isRecording: Bool { recorder?.isRecording ?? false }

    func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        default:
            return false
        }
    }

    func startRecording() throws -> URL {
        // Defense in depth: a stray active recorder must never keep the mic
        // open behind a new session.
        if let recorder, recorder.isRecording {
            Log.audio.error("startRecording called while already recording; stopping the previous session")
            recorder.stop()
            self.recorder = nil
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenDictation-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            // 32 kbps is transparent for 16 kHz mono speech and keeps the clip
            // tiny, so the upload — the real latency cost — finishes sooner.
            AVEncoderBitRateKey: 32_000,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        guard recorder.record() else {
            throw AppError.audioRecordingFailed
        }
        self.recorder = recorder
        return url
    }

    func stopRecording() -> URL? {
        guard let recorder else { return nil }
        let url = recorder.url
        recorder.stop()
        self.recorder = nil
        return url
    }

    func currentPowerLevel() -> Float {
        guard let recorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        // averagePower is in dBFS (-160…0); anything below the floor renders
        // as silence so ambient noise doesn't make the waveform jitter.
        let decibelFloor: Float = -50
        let decibels = recorder.averagePower(forChannel: 0)
        return max(0, min(1, (decibels - decibelFloor) / -decibelFloor))
    }
}
