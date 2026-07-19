import AVFoundation

/// `AVAudioRecorder`-backed implementation of `AudioRecording`.
///
/// Records mono AAC (.m4a) into the user's temporary directory — small enough
/// to upload quickly, and never persisted anywhere permanent. Metering is
/// enabled so the UI can render a live waveform.
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
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenDictation-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
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
