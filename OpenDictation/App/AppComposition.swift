import Foundation
import Observation

/// Builds the dependency graph and the dictation controller exactly once,
/// giving every scene a single object to hang on to.
@MainActor
@Observable
final class AppComposition {
    let dependencies: AppDependencies
    let controller: DictationController
    let navigator = DesktopNavigator()

    init() {
        dependencies = .live()
        controller = DictationController(dependencies: dependencies)
    }
}
