# How KeepClean Works

A brief overview of the app's design for curious users and contributors.

## How It Disables Input

KeepClean uses Apple's `CGEvent` tap API to intercept keyboard and trackpad events at the system level:

1. **Creates an event tap** — a low-level hook that sees every keyboard event before it reaches any app.
2. **Drops events** — the tap callback returns `nil`, which tells macOS to discard the event entirely.
3. **Restores on release** — when you re-enable the keyboard, the tap is destroyed and events flow normally again.

For the trackpad, KeepClean also uses `CGAssociateMouseAndMouseCursorPosition` to dissociate the cursor from trackpad movement, and hides the cursor for a cleaner experience.

## Why Two Permissions?

macOS separates the ability to *see* events (Input Monitoring) from the ability to *modify/block* them (Accessibility). KeepClean needs both:

- **Accessibility** — lets the app create an active event tap.
- **Input Monitoring** — lets the tap actually suppress events instead of just observing them.

## App Structure

```
KeepClean.app
├── KeepClean         (main app — UI, settings, keyboard-only blocking)
└── KeepCleanHelper   (helper tool — timed keyboard+trackpad blocking)
```

- The **main app** handles keyboard-only mode directly.
- The **helper process** manages timed keyboard+trackpad mode so the countdown and auto-recovery work even if the main window closes.

## Why It Quits on Close

KeepClean is a utility, not a background service. Quitting on close ensures:

- No surprises — when the window is gone, the app is gone.
- All input is immediately restored.
- No menu bar icon, no Dock persistence, no hidden processes.

## What the Release Checks Verify

Before packaging, the release script verifies:

- Unit tests pass
- App launches without crashing
- Bundle size stays within budget
- Memory usage is reasonable
- Code signing is valid
- All expected resources are present
