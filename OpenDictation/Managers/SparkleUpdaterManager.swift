import Foundation
import Sparkle

/// Capability: checking for and installing app updates.
@MainActor
protocol UpdateManaging: AnyObject {
    var automaticallyChecksForUpdates: Bool { get set }
    func checkForUpdates()
}

/// Sparkle-backed updates from the GitHub Releases feed (see `SUFeedURL` in
/// Info.plist; signatures verified against `SUPublicEDKey`).
///
/// The updater is created lazily on first use: unit tests and CI launch the
/// app as a test host, and must never trigger update checks or permission
/// prompts.
@MainActor
final class SparkleUpdaterManager: UpdateManaging {
    private var controller: SPUStandardUpdaterController?

    private var updater: SPUUpdater {
        if controller == nil {
            controller = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        }
        return controller!.updater
    }

    var automaticallyChecksForUpdates: Bool {
        get { updater.automaticallyChecksForUpdates }
        set { updater.automaticallyChecksForUpdates = newValue }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
