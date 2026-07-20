import AppKit
import SwiftUI

/// Gives the hosting window a frame autosave name so macOS persists and
/// restores its size and position across launches. Drop it into a view's
/// `.background`.
struct WindowConfigurator: NSViewRepresentable {
    let autosaveName: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // The window isn't attached yet during makeNSView; defer a tick.
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.setFrameAutosaveName(autosaveName)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
