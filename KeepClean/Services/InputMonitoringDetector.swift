@preconcurrency import ApplicationServices
import Foundation
import IOKit.hid
import os.log

private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "InputMonitoringDetector")

/// Single source of truth for detecting whether Input Monitoring is granted.
///
/// macOS TCC is notoriously unreliable for ad-hoc signed builds — a single API
/// call is insufficient. This struct tries four methods in order and returns
/// `true` on the first success.  All three callers (PermissionSetupViewModel,
/// AppViewModel, and ContentGateView) use this instead of duplicating logic.
enum InputMonitoringDetector {

    // MARK: - Public API

    /// Returns `true` if Input Monitoring is granted by any detection method.
    static func isGranted() -> Bool {
        // Method 1: Try creating a temporary listenOnly CGEvent tap.
        // Most reliable at runtime — directly tests whether the OS will allow the tap.
        if checkViaTestEventTap() {
            logger.debug("Input Monitoring detected via test event tap.")
            return true
        }

        // Method 2: Official Apple API (may lag behind actual state for running processes).
        if CGPreflightListenEventAccess() {
            logger.debug("Input Monitoring detected via CGPreflightListenEventAccess.")
            return true
        }

        // Method 3: Try to seize a HID keyboard device.
        if checkViaHIDSeize() {
            logger.debug("Input Monitoring detected via HID seize.")
            return true
        }

        // Method 4: Check whether built-in SPI/I2C pointer devices are accessible.
        if checkViaHIDOpen() {
            logger.debug("Input Monitoring detected via HID open.")
            return true
        }

        logger.debug("Input Monitoring NOT detected by any method.")
        return false
    }

    // MARK: - Private Methods

    /// Attempts to create a temporary listenOnly CGEvent tap.
    /// If the system allows creation, Input Monitoring is granted.
    /// The tap is immediately destroyed — we only need creation to succeed.
    private static func checkViaTestEventTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: inputMonitoringDetectorPassthroughCallback,
            userInfo: nil
        ) else {
            return false
        }

        CFMachPortInvalidate(tap)
        return true
    }

    private static func checkViaHIDSeize() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Keyboard,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openStatus == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return false
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        var granted = false
        for device in devices {
            let status = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
            if status == kIOReturnSuccess {
                IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
                granted = true
                break
            }
            if status == IOReturn(kIOReturnExclusiveAccess) {
                granted = true
                break
            }
        }

        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        return granted
    }

    private static func checkViaHIDOpen() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matchingList: [[String: Any]] = [
            [kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
             kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Mouse],
            [kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
             kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Pointer],
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingList as CFArray)

        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openStatus == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return false
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        let hasBuiltIn = devices.contains { device in
            let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? ""
            return ["SPI", "I2C", "spi", "i2c"].contains(transport)
        }

        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        return hasBuiltIn
    }
}

// MARK: - C-compatible passthrough callback

/// Free function required for CGEvent tap creation (must be C-callable).
/// Simply passes events through — the tap is only created to test permission, then destroyed.
private func inputMonitoringDetectorPassthroughCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    Unmanaged.passUnretained(event)
}
