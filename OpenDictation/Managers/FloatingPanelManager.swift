import AppKit
import SwiftUI

/// Owns the floating recorder panel: a borderless, non-activating `NSPanel`
/// that stays above all windows without ever stealing keyboard focus from the
/// app the user is dictating into. SwiftUI cannot create this window style
/// itself, which is why this thin AppKit wrapper exists.
@MainActor
final class FloatingPanelManager {
    private let settings: SettingsStore
    private var panel: NSPanel?

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func show<Content: View>(@ViewBuilder content: () -> Content) {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.appearance = Self.appearance(for: settings.panelAppearance)

        let hosting = NSHostingView(rootView: content())
        // Let SwiftUI drive the window size as the popup's state changes.
        hosting.sizingOptions = [.preferredContentSize]
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        position(panel)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = settings.panelOpacity
        }
    }

    private static func appearance(for mode: PanelAppearanceMode) -> NSAppearance? {
        switch mode {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            // AppKit calls the completion on the main thread; the SDK just
            // hasn't annotated it as such.
            MainActor.assumeIsolated {
                panel.orderOut(nil)
            }
        })
    }

    /// Bottom-center of the active screen, like the system dictation HUD.
    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - panel.frame.width / 2,
            y: visible.minY + 140
        )
        panel.setFrameOrigin(origin)
    }

    private func makePanel() -> NSPanel {
        let panel = RecorderPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        return panel
    }
}

/// Refuses key/main status entirely: the user's keyboard focus must stay in
/// the app they were typing in. Mouse clicks still reach the panel's controls.
private final class RecorderPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
