import Testing
@testable import OpenDictation

@MainActor
struct CommandPaletteModelTests {
    private final class Box { var hit: String? }

    private func sampleItems(box: Box = Box()) -> [CommandItem] {
        [
            CommandItem(title: "Go to Home", subtitle: "Navigate", icon: "house", keywords: ["dashboard"], perform: { box.hit = "home" }),
            CommandItem(title: "Start Dictation", subtitle: "Recorder", icon: "mic", keywords: ["record", "voice"], perform: { box.hit = "dictation" }),
            CommandItem(title: "Check for Updates", subtitle: "Sparkle", icon: "arrow", keywords: ["upgrade"], perform: { box.hit = "updates" }),
        ]
    }

    @Test func emptyQueryReturnsEverything() {
        let model = CommandPaletteModel(items: sampleItems())
        #expect(model.filtered.count == 3)
    }

    @Test func filtersByTitleSubtitleAndKeywords() {
        let model = CommandPaletteModel(items: sampleItems())

        model.query = "dictation"
        #expect(model.filtered.map(\.title) == ["Start Dictation"])

        model.query = "voice" // keyword only
        #expect(model.filtered.map(\.title) == ["Start Dictation"])

        model.query = "sparkle" // subtitle only
        #expect(model.filtered.map(\.title) == ["Check for Updates"])

        model.query = "zzz"
        #expect(model.filtered.isEmpty)
    }

    @Test func arrowNavigationWraps() {
        let model = CommandPaletteModel(items: sampleItems())
        #expect(model.selectedIndex == 0)

        model.moveDown()
        #expect(model.selectedIndex == 1)
        model.moveDown()
        model.moveDown() // 3 items → wraps back to 0
        #expect(model.selectedIndex == 0)

        model.moveUp() // wraps to last
        #expect(model.selectedIndex == 2)
    }

    @Test func selectionClampsWhenResultsShrink() {
        let model = CommandPaletteModel(items: sampleItems())
        model.moveDown()
        model.moveDown() // index 2
        #expect(model.selectedIndex == 2)

        model.query = "dictation" // one result now
        #expect(model.selectedIndex == 0)
    }

    @Test func executeSelectedRunsTheHighlightedAction() {
        let box = Box()
        let model = CommandPaletteModel(items: sampleItems(box: box))

        model.moveDown() // select "Start Dictation"
        model.executeSelected()

        #expect(box.hit == "dictation")
    }

    @Test func executeWithNoResultsIsSafe() {
        let box = Box()
        let model = CommandPaletteModel(items: sampleItems(box: box))
        model.query = "no-match"

        model.executeSelected()

        #expect(box.hit == nil)
    }
}
