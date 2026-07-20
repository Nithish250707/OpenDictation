import AppKit
import SwiftUI

/// The desktop window's sidebar: brand header, grouped navigation, and a
/// footer with a quick record action.
struct SidebarView: View {
    let composition: AppComposition

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        @Bindable var navigator = composition.navigator

        List(selection: $navigator.selection) {
            Section {
                row(.home)
                row(.history)
            }
            Section("Workspace") {
                row(.aiProfiles)
                row(.dictionary)
            }
            Section {
                row(.settings)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) { brandHeader }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    private func row(_ section: DesktopSection) -> some View {
        Label(section.title, systemImage: section.symbol)
            .tag(section)
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text("Open Dictation")
                    .font(.headline)
                Text("Version \(version)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                composition.controller.toggleDictation()
            } label: {
                Label("Start Dictation", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(12)
        }
    }
}
