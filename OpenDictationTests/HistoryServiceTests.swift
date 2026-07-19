import Foundation
import Testing
@testable import OpenDictation

@MainActor
struct HistoryServiceTests {
    private func makeTranscript(_ text: String, at date: Date = .now) -> Transcript {
        Transcript(text: text, duration: 2, providerID: "openai", model: "whisper-1", createdAt: date)
    }

    @Test func savedTranscriptsComeBackNewestFirst() throws {
        let service = HistoryService.inMemory()

        try service.save(makeTranscript("older", at: .now.addingTimeInterval(-60)))
        try service.save(makeTranscript("newer", at: .now))

        let records = try service.records(matching: nil)
        #expect(records.map(\.text) == ["newer", "older"])
    }

    @Test func recordCarriesAllTranscriptFields() throws {
        let service = HistoryService.inMemory()
        let createdAt = Date.now

        try service.save(Transcript(text: "Hello", duration: 3.5, providerID: "openai", model: "gpt-4o-transcribe", createdAt: createdAt))

        let record = try #require(try service.records(matching: nil).first)
        #expect(record.text == "Hello")
        #expect(record.duration == 3.5)
        #expect(record.providerID == "openai")
        #expect(record.modelName == "gpt-4o-transcribe")
        #expect(record.createdAt == createdAt)
    }

    @Test func searchMatchesCaseInsensitively() throws {
        let service = HistoryService.inMemory()
        try service.save(makeTranscript("Remind me to buy groceries"))
        try service.save(makeTranscript("Draft the quarterly report"))

        #expect(try service.records(matching: "GROCERIES").map(\.text) == ["Remind me to buy groceries"])
        #expect(try service.records(matching: "meeting").isEmpty)
        #expect(try service.records(matching: "").count == 2)
    }

    @Test func deleteRemovesOnlyThatRecord() throws {
        let service = HistoryService.inMemory()
        try service.save(makeTranscript("keep me", at: .now.addingTimeInterval(-10)))
        try service.save(makeTranscript("delete me"))

        let doomed = try #require(try service.records(matching: "delete").first)
        try service.delete(doomed)

        #expect(try service.records(matching: nil).map(\.text) == ["keep me"])
    }

    @Test func deleteAllEmptiesTheStore() throws {
        let service = HistoryService.inMemory()
        try service.save(makeTranscript("one"))
        try service.save(makeTranscript("two"))

        try service.deleteAll()

        #expect(try service.records(matching: nil).isEmpty)
    }
}
