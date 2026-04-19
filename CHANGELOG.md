# Changelog

All notable changes to KeepClean are documented here.

## 1.0.0

**First public release.**

### Features

- **Disable Keyboard** — turn off the built-in keyboard while keeping the trackpad active.
- **Disable Keyboard + Trackpad** — turn off both for a configurable timer (15–180 seconds) with automatic recovery.
- **Auto-start** — optionally begin keyboard-only cleaning the moment you open the app.
- **One-time setup** — guided permission screen walks you through granting Accessibility and Input Monitoring.
- **Permission banners** — clear in-app guidance if a permission is missing or revoked.
- **Manual override** — for ad-hoc signed builds where macOS detection is unreliable, confirm permissions manually.

### Safety

- Keyboard-only mode keeps the trackpad active at all times.
- Timed mode always has a hard deadline and auto-recovers.
- Closing the window fully quits the app and restores all input.
- External keyboards and mice are never affected.

### Technical

- Built with Swift and SwiftUI, targeting macOS 13.0 (Ventura) and later.
- Uses `CGEvent` taps for keyboard blocking and `CGAssociateMouseAndMouseCursorPosition` for trackpad blocking.
- Diagnostic logging via `os.log` for troubleshooting (visible in Console.app).
- No analytics, no networking, no background processes.
