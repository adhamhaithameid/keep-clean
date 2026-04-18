# Install From GitHub

This guide is for people downloading KeepClean from the GitHub repository or its Releases page.

## Option 1: Download a Ready-Made Build

1. Open the latest [Releases page](https://github.com/adhamhaithameid/keep-clean/releases).
2. Download either:
   - the `.dmg` if you want the usual drag-to-Applications flow with an installer window
   - the `.zip` if you prefer a plain archive
3. If you downloaded the `.dmg`, drag `KeepClean.app` onto the `Applications` shortcut in that window.
4. If you downloaded the `.zip`, move `KeepClean.app` into `Applications`.
5. Open it with a right click the first time if macOS warns that it came from the internet.

## After You Open It

1. Go to `Clean`.
2. Start with `Disable Keyboard`.
3. If macOS asks for permission, allow it.
4. If KeepClean says macOS still needs approval, use the `Open Privacy & Security` button in `Settings` or the error panel.
5. Confirm the trackpad stays active.
6. Re-enable the keyboard.

Then run the rest of the [Post-Install Checklist](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/manual-testing.md).

## If You Want to Verify the Download

- If you built the app locally, compare your files with [SHA256SUMS.txt](/Users/adhamhaithameid/Desktop/code/keep-clean/release/SHA256SUMS.txt).
- If you downloaded a GitHub release asset, compare it with the checksum published alongside that release when available.

## Optional: Build It Yourself

If you prefer building from source instead of downloading a packaged release:

```bash
git clone https://github.com/adhamhaithameid/keep-clean.git
cd keep-clean
xcodegen generate
./script/run_release_checks.sh
```

That produces:

- `release/KeepClean.app`
- `release/KeepClean-<version>-macOS.zip`
- `release/KeepClean-<version>-macOS.dmg`
- `release/SHA256SUMS.txt`

## If Something Goes Wrong

- Check [Permissions](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/permissions.md) if macOS blocks the cleaning actions.
- Check [Troubleshooting](/Users/adhamhaithameid/Desktop/code/keep-clean/docs/troubleshooting.md) if the app opens but does not behave the way you expect.
