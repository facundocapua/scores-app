import Foundation
import Testing
@testable import Porotos

struct EntryLogTests {
    @Test func undoRemovesAddedEntriesInReverseOrder() {
        var log = EntryLog<Int>()
        log.add(1)
        log.add(2)
        log.add(3)

        let undid = log.undo()
        #expect(undid)
        #expect(log.entries == [1, 2])
        log.undo()
        log.undo()
        #expect(log.entries.isEmpty)
        #expect(!log.canUndo)
        let undidWithNoChanges = log.undo()
        #expect(!undidWithNoChanges)
    }

    @Test func undoRestoresThePreviousValueOfAnEdit() {
        var log = EntryLog<Int>()
        log.add(10)
        log.add(20)
        log.edit(at: 0, with: 15)

        #expect(log.entries == [15, 20])
        log.undo()
        #expect(log.entries == [10, 20])
        log.undo()
        #expect(log.entries == [10])
    }

    @Test func editingWithTheSameValueIsNotAChange() {
        var log = EntryLog<Int>()
        log.add(10)
        log.edit(at: 0, with: 10)

        log.undo()
        #expect(log.entries.isEmpty)
    }

    @Test func undoPutsARemovedEntryBackInPlace() {
        var log = EntryLog<Int>()
        log.add(1)
        log.add(2)
        log.add(3)
        log.remove(at: 1)

        #expect(log.entries == [1, 3])
        log.undo()
        #expect(log.entries == [1, 2, 3])
    }

    @Test func mixedChangesAreUndoneInOrder() {
        var log = EntryLog<Int>()
        log.add(1)
        log.add(2)
        log.edit(at: 0, with: 5)
        log.remove(at: 1)
        log.add(9)
        let states: [[Int]] = [[5, 9], [5], [5, 2], [1, 2], [1], []]

        #expect(log.entries == states[0])
        for expected in states.dropFirst() {
            log.undo()
            #expect(log.entries == expected)
        }
    }

    @Test func theChangeHistorySurvivesEncoding() throws {
        var log = EntryLog<Int>()
        log.add(1)
        log.edit(at: 0, with: 2)

        var decoded = try Coding.decode(EntryLog<Int>.self, from: try Coding.encode(log))
        #expect(decoded == log)
        decoded.undo()
        #expect(decoded.entries == [1])
    }
}

struct OutcomeTests {
    @Test func leadersIncludeEveryoneTiedAtTheTop() {
        #expect(Outcome.leaders([3, 7, 7, 1]) == [1, 2])
        #expect(Outcome.leaders([5]) == [0])
        #expect(Outcome.leaders([]) == [])
    }
}
