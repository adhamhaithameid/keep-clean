# Troubleshooting

## macOS Says the App Cannot Be Opened

- Try a right click on `KeepClean.app`, then choose `Open`.
- If macOS still blocks it, open `System Settings > Privacy & Security` and look for the approval message for KeepClean.

## The App Opens but Cleaning Does Nothing

- Try `Disable Keyboard` first.
- Watch for a permission prompt.
- If the app shows a plain-language error, use `Open Privacy & Security`, allow the requested access, and try again.

## The Timed Clean Did Not Start

- Open `Settings` and confirm the duration is set to a value between `15` and `180` seconds.
- Return to `Clean` and try again.
- If the error mentions the helper, quit the app and reopen it.

## The App Feels Stuck

- Close the window. KeepClean is designed to fully quit.
- Re-open the app and try the keyboard-only action first.

## You Want to Confirm the Build You Downloaded

- Compare the file hashes in `release/SHA256SUMS.txt` if you built the app yourself.
- If you downloaded a release asset, compare it with the published checksum from that release when available.
