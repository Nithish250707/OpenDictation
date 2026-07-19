import AVFoundation
import Foundation

enum PermissionState: Equatable {
    case granted
    case denied
    case notDetermined
}

/// Capability: reading current system permission states without prompting.
@MainActor
protocol PermissionStatusChecking: AnyObject {
    var microphone: PermissionState { get }
    var accessibilityGranted: Bool { get }
}

final class SystemPermissionStatus: PermissionStatusChecking {
    private let accessibility: any AccessibilityPermissionChecking

    init(accessibility: any AccessibilityPermissionChecking) {
        self.accessibility = accessibility
    }

    var microphone: PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    var accessibilityGranted: Bool {
        accessibility.isGranted
    }
}
