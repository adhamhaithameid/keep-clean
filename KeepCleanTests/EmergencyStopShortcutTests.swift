import XCTest

@testable import KeepClean

final class EmergencyStopShortcutTests: XCTestCase {

    // MARK: - Helpers

    private let bothCmds =
        EmergencyStopShortcut.leftCommandMask | EmergencyStopShortcut.rightCommandMask
    private var both10: Set<Int64> {
        [EmergencyStopShortcut.keyCode1, EmergencyStopShortcut.keyCode0]
    }

    private func isActive(flags: UInt, keys: Set<Int64>) -> Bool {
        EmergencyStopShortcut.isActive(modifierFlagsRawValue: flags, pressedKeyCodes: keys)
    }

    // MARK: - Modifier flag requirements

    func testNoModifiers_notActive() {
        XCTAssertFalse(isActive(flags: 0, keys: both10))
    }

    func testOnlyLeftCommand_notActive() {
        XCTAssertFalse(isActive(flags: EmergencyStopShortcut.leftCommandMask, keys: both10))
    }

    func testOnlyRightCommand_notActive() {
        XCTAssertFalse(isActive(flags: EmergencyStopShortcut.rightCommandMask, keys: both10))
    }

    func testBothCommandKeys_withBoth10_isActive() {
        XCTAssertTrue(isActive(flags: bothCmds, keys: both10))
    }

    // MARK: - Character key requirements

    func testBothCommands_emptyKeySet_notActive() {
        XCTAssertFalse(isActive(flags: bothCmds, keys: []))
    }

    func testBothCommands_only1Key_notActive() {
        XCTAssertFalse(isActive(flags: bothCmds, keys: [EmergencyStopShortcut.keyCode1]))
    }

    func testBothCommands_only0Key_notActive() {
        XCTAssertFalse(isActive(flags: bothCmds, keys: [EmergencyStopShortcut.keyCode0]))
    }

    func testBothCommands_unrelatedKey_notActive() {
        XCTAssertFalse(isActive(flags: bothCmds, keys: [99]))
    }

    func testBothCommands_1andUnrelated_notActive() {
        XCTAssertFalse(isActive(flags: bothCmds, keys: [EmergencyStopShortcut.keyCode1, 99]))
    }

    func testBothCommands_0andUnrelated_notActive() {
        XCTAssertFalse(isActive(flags: bothCmds, keys: [EmergencyStopShortcut.keyCode0, 99]))
    }

    // MARK: - Extra modifiers / keys should not block the shortcut

    func testBothCommandsPlusShift_with10_isActive() {
        // Holding Shift at the same time must not prevent the shortcut from firing.
        let shiftMask: UInt = 0x0002_0000  // NSEvent.ModifierFlags.shift raw value
        XCTAssertTrue(isActive(flags: bothCmds | shiftMask, keys: both10))
    }

    func testBothCommandsPlusControl_with10_isActive() {
        let controlMask: UInt = 0x0004_0000
        XCTAssertTrue(isActive(flags: bothCmds | controlMask, keys: both10))
    }

    func testBothCommands_10plusExtraKey_isActive() {
        // Other keys held alongside 1 and 0 must not block the shortcut.
        var keys = both10
        keys.insert(36)  // Return key
        keys.insert(53)  // Escape key
        XCTAssertTrue(isActive(flags: bothCmds, keys: keys))
    }

    // MARK: - Constant sanity checks

    func testLeftCommandMaskValue() {
        XCTAssertEqual(EmergencyStopShortcut.leftCommandMask, 0x0000_0008)
    }

    func testRightCommandMaskValue() {
        XCTAssertEqual(EmergencyStopShortcut.rightCommandMask, 0x0000_0010)
    }

    func testKeyCode1Value() {
        XCTAssertEqual(EmergencyStopShortcut.keyCode1, 18)
    }

    func testKeyCode0Value() {
        XCTAssertEqual(EmergencyStopShortcut.keyCode0, 29)
    }

    // MARK: - Masks are distinct and non-overlapping

    func testLeftAndRightMasksDoNotOverlap() {
        XCTAssertEqual(
            EmergencyStopShortcut.leftCommandMask & EmergencyStopShortcut.rightCommandMask, 0,
            "Left and right command masks must occupy different bits"
        )
    }

    func testBothMasksCombinedCoversIndividualMasks() {
        XCTAssertEqual(
            bothCmds & EmergencyStopShortcut.leftCommandMask, EmergencyStopShortcut.leftCommandMask)
        XCTAssertEqual(
            bothCmds & EmergencyStopShortcut.rightCommandMask,
            EmergencyStopShortcut.rightCommandMask)
    }
}
