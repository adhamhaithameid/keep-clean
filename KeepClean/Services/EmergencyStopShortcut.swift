import Foundation

// MARK: - EmergencyStopShortcut
//
// Pure detection logic for the four-key emergency stop combination:
//
//   Left ⌘  +  Right ⌘  +  1  +  0
//
// Design: completely stateless so it can be unit-tested without any
// CGEvent / NSEvent / hardware dependencies.  The caller
// (KeyboardBlockerResource) is responsible for maintaining the set of
// currently-pressed key codes across keyDown / keyUp events.

struct EmergencyStopShortcut {

    // MARK: - Constants

    /// Device-dependent left-Command mask  (NX_DEVICELCMDKEYMASK = 0x08).
    /// Present in CGEventFlags.rawValue when the physical left ⌘ key is held.
    static let leftCommandMask: UInt = 0x0000_0008

    /// Device-dependent right-Command mask  (NX_DEVICERCMDKEYMASK = 0x10).
    /// Present in CGEventFlags.rawValue when the physical right ⌘ key is held.
    static let rightCommandMask: UInt = 0x0000_0010

    /// ANSI key code for the "1" key  (kVK_ANSI_1 = 18).
    static let keyCode1: Int64 = 18

    /// ANSI key code for the "0" key  (kVK_ANSI_0 = 29).
    static let keyCode0: Int64 = 29

    // MARK: - Detection

    /// Returns `true` when all four keys of the emergency stop chord are
    /// simultaneously active.
    ///
    /// - Parameters:
    ///   - modifierFlagsRawValue: Raw `UInt` of the current `CGEventFlags`
    ///     (obtained via `event.flags.rawValue`).
    ///   - pressedKeyCodes: The set of character key codes currently held down,
    ///     maintained by the caller across consecutive `keyDown` / `keyUp` events.
    static func isActive(
        modifierFlagsRawValue: UInt,
        pressedKeyCodes: Set<Int64>
    ) -> Bool {
        guard modifierFlagsRawValue & leftCommandMask != 0,
            modifierFlagsRawValue & rightCommandMask != 0
        else { return false }

        return pressedKeyCodes.contains(keyCode1) && pressedKeyCodes.contains(keyCode0)
    }
}
