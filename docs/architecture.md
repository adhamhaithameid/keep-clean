# How KeepClean Works

KeepClean uses Apple frameworks and a very small app structure so it can stay lightweight and predictable.

## What the App Does

- The main window gives you two cleaning actions, one settings page, and one about page.
- The built-in keyboard action is controlled directly by the app.
- The built-in keyboard + trackpad action is controlled by a tiny helper process with a deadline, so the timed clean can finish even if the main window closes.

## Why There Is a Helper

The strict timed clean needs to recover automatically. If the main app owned that lock and crashed or closed at the wrong moment, the behavior would be harder to trust. The helper exists to keep that timed path isolated and simpler.

## Why the App Stays Small

- It only supports the built-in keyboard and built-in trackpad.
- It does not scan for or manage external keyboards or mice.
- It does not bundle networking features, auto-update frameworks, analytics SDKs, or account systems.
- It uses native Swift and SwiftUI instead of a heavier cross-platform stack.

## What Release Checks Verify

Before packaging installable builds, the release checks verify:

- logic checks for the core models
- unit tests for settings, lock state, helper launch requests, helper launching, and app state transitions
- a launch smoke test
- app bundle contents
- code signing verification
- bundle size budget
- memory budget after launch

If you are building from source, run:

```bash
./script/run_release_checks.sh
```
