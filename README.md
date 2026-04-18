# KeepClean

KeepClean is a simple macOS utility that lets you temporarily disable your built-in keyboard, or your built-in keyboard and trackpad together, so you can clean your Mac without accidental typing or clicking.

It is intentionally small and focused:

- no accounts
- no analytics
- no sync
- no background networking
- no external keyboard or mouse support in this version

## Quick Start

1. Open the latest [GitHub release](https://github.com/adhamhaithameid/keep-clean/releases).
2. Download either the `.dmg` or the `.zip`.
3. If you use the `.dmg`, it opens a drag-to-Applications installer window. If you use the `.zip`, move `KeepClean.app` into `Applications` yourself.
4. Open it with a right click the first time if macOS warns that it came from the internet.
5. Start with `Disable Keyboard` for your first real test.

If you want the full install guide, see [Install From GitHub](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/install-from-github.md).

## What the App Does

- `Disable Keyboard`
  - turns off only the built-in keyboard
  - keeps the built-in trackpad active
  - lets you re-enable the keyboard from the same button
- `Disable Keyboard + Trackpad`
  - turns off both for the timer you choose in Settings
  - restores both automatically when the timer ends
- `Settings`
  - choose a full-clean duration from `15` to `180` seconds
  - optionally start keyboard-only cleaning automatically after opening the app
- `About`
  - your GitHub profile link
  - your repository link
  - your Buy Me a Coffee link

## Before You Rely On It

Run the short [Post-Install Checklist](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/manual-testing.md). It helps you confirm the permission flow, timer, auto-start, and recovery behavior on your own Mac first.

## Safety

- Keyboard-only mode is the safest option because the trackpad stays active.
- Timed full-clean always has a deadline and tries to recover automatically.
- The timed clean is handled by a helper so it can finish even if the main window closes.
- Closing the window fully quits the app.

More detail is in [Safety Notes](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/safety.md).

## Permissions

macOS may ask for permission the first time you try a real cleaning action.

- If macOS prompts, allow access.
- If access is denied, KeepClean stays usable and shows a plain-language error instead of leaving your Mac half-disabled.
- KeepClean also includes an `Open Privacy & Security` button in the app when you need to approve it.
- `Disable Keyboard` is the safest first test because the trackpad remains active.

See [Permissions](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/permissions.md).

## Documentation

- [Install From GitHub](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/install-from-github.md)
- [Post-Install Checklist](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/manual-testing.md)
- [Permissions](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/permissions.md)
- [Safety Notes](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/safety.md)
- [Privacy and Footprint](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/privacy.md)
- [FAQ](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/faq.md)
- [Troubleshooting](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/troubleshooting.md)
- [Uninstall KeepClean](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/uninstall.md)
- [How KeepClean Works](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/architecture.md)

## Installable Builds

The current packaged outputs live here when you build locally:

- [KeepClean.app](/Users/adhamhaithameid/Desktop/code/keep-clean/release/KeepClean.app)
- [KeepClean-1.0.0-macOS.zip](/Users/adhamhaithameid/Desktop/code/keep-clean/release/KeepClean-1.0.0-macOS.zip)
- [KeepClean-1.0.0-macOS.dmg](/Users/adhamhaithameid/Desktop/code/keep-clean/release/KeepClean-1.0.0-macOS.dmg)
- [SHA256SUMS.txt](/Users/adhamhaithameid/Desktop/code/keep-clean/release/SHA256SUMS.txt)

## License

This project is source-available under [PolyForm Noncommercial 1.0.0](/Users/adhamhaithameid/Desktop/code/keep-clean/LICENSE.md).
