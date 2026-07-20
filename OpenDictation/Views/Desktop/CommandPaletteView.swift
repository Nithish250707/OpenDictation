import SwiftUI

/// A Raycast-style command palette (⌘K): type to filter navigation and
/// actions, arrow keys to move, Return to run, Escape to dismiss.
struct CommandPaletteView: View {
    let composition: AppComposition
    @Binding var isPresented: Bool

    @State private var model: CommandPaletteModel
    @FocusState private var searchFocused: Bool

    init(composition: AppComposition, isPresented: Binding<Bool>) {
        self.composition = composition
        self._isPresented = isPresented
        self._model = State(initialValue: CommandPaletteModel(
            items: Self.commands(composition: composition, isPresented: isPresented)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            results
        }
        .frame(width: 560, height: 420)
        .background(.regularMaterial)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title3)
            TextField("Search commands…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .onSubmit { run() }
                .onKeyPress(.downArrow) { model.moveDown(); return .handled }
                .onKeyPress(.upArrow) { model.moveUp(); return .handled }
                .onKeyPress(.escape) { isPresented = false; return .handled }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .onAppear { searchFocused = true }
    }

    @ViewBuilder
    private var results: some View {
        if model.filtered.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title)
                    .foregroundStyle(.tertiary)
                Text("No matching commands")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.filtered.enumerated()), id: \.element.id) { index, item in
                            row(item, isSelected: index == model.selectedIndex)
                                .id(index)
                                .onTapGesture {
                                    model.selectedIndex = index
                                    run()
                                }
                        }
                    }
                    .padding(8)
                }
                .onChange(of: model.selectedIndex) { _, index in
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }

    private func row(_ item: CommandItem, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.body)
                .foregroundStyle(isSelected ? Color.white : .secondary)
                .frame(width: 30, height: 30)
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.body.weight(.medium))
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "return")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected ? AnyShapeStyle(.tint.opacity(0.14)) : AnyShapeStyle(.clear),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .contentShape(Rectangle())
    }

    private func run() {
        model.executeSelected()
    }

    // MARK: - Command catalog

    private static func commands(composition: AppComposition, isPresented: Binding<Bool>) -> [CommandItem] {
        func action(_ block: @escaping () -> Void) -> () -> Void {
            {
                isPresented.wrappedValue = false
                block()
            }
        }

        let navigator = composition.navigator
        var items: [CommandItem] = DesktopSection.allCases.map { section in
            CommandItem(
                title: "Go to \(section.title)",
                subtitle: "Navigate",
                icon: section.symbol,
                keywords: [section.title, "open", "navigate"],
                perform: action { navigator.go(to: section) }
            )
        }

        items.append(CommandItem(
            title: "Start Dictation",
            subtitle: "Open the floating recorder",
            icon: "mic.fill",
            keywords: ["record", "dictate", "voice"],
            perform: action { composition.controller.toggleDictation() }
        ))
        items.append(CommandItem(
            title: "Check for Updates",
            subtitle: "Look for a newer version",
            icon: "arrow.triangle.2.circlepath",
            keywords: ["update", "sparkle", "upgrade"],
            perform: action { composition.dependencies.updater.checkForUpdates() }
        ))
        items.append(CommandItem(
            title: "Open Microphone Settings",
            subtitle: "System Settings → Privacy",
            icon: "mic",
            keywords: ["permission", "privacy", "system"],
            perform: action { SystemSettingsDeepLink.open(SystemSettingsDeepLink.microphone) }
        ))
        items.append(CommandItem(
            title: "Open Accessibility Settings",
            subtitle: "System Settings → Privacy",
            icon: "hand.raised",
            keywords: ["permission", "paste", "privacy", "system"],
            perform: action { SystemSettingsDeepLink.open(SystemSettingsDeepLink.accessibility) }
        ))
        return items
    }
}
