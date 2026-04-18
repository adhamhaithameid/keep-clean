# Permissions

KeepClean talks to the built-in keyboard and trackpad through Apple HID APIs. macOS may ask for permission the first time you run a real cleaning action.

## What to Expect

- The app can open and display its interface without special permission.
- A permission prompt may appear only when you trigger a real clean.
- If access is denied, KeepClean shows an error and leaves your Mac usable.

## Best First Test

Use `Disable Keyboard` first.

That mode keeps the trackpad active, which makes it the safest way to confirm the permission flow on your Mac.

## If You Do Not See a Prompt

1. Quit KeepClean.
2. Open it again.
3. Try `Disable Keyboard`.
4. Watch for a system prompt or a message in the app.

## If You Previously Denied Access

1. Open KeepClean.
2. Use the `Open Privacy & Security` button in `Settings`, or use the same button shown in the error panel after a failed clean.
3. Review the relevant privacy or security prompt area macOS shows for HID access on your system version.
4. Re-open KeepClean and try again.

If the app still says access was denied, check [Troubleshooting](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/troubleshooting.md).
