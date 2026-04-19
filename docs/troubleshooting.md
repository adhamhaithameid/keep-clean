# Troubleshooting

## macOS Says the App Can't Be Opened

This happens because KeepClean isn't notarized through the App Store:

1. Right-click `KeepClean.app` → **Open** → click **Open** in the dialog.
2. If that doesn't work, go to **System Settings → Privacy & Security** and look for a message about KeepClean — click **Open Anyway**.

## The Setup Screen Doesn't Detect Input Monitoring

If you've granted Input Monitoring but the indicator stays red:

1. Wait 10 seconds — an **"I've Already Granted It"** button will appear.
2. Click it to proceed. This is common with ad-hoc signed builds.
3. The actual blocking works correctly as long as the permission is toggled on in System Settings.

You can also try clicking **Refresh Detection** or quitting and reopening the app.

## The Keyboard Isn't Actually Blocked

If you click **Disable Keyboard** but keys still type:

1. Check that **Input Monitoring** is granted in System Settings → Privacy & Security → Input Monitoring.
2. Make sure KeepClean is toggled **ON** in the list (not just present).
3. Try quitting KeepClean, removing it from Input Monitoring, re-adding it, and reopening.
4. If you rebuilt the app from source, you may need to re-grant permissions (the code signature changed).

## The Timed Clean Didn't Start

1. Open **Settings** and confirm the duration is between 15 and 180 seconds.
2. Make sure no other cleaning session is already active.
3. Check that both Accessibility and Input Monitoring permissions are granted.

## The App Feels Stuck

1. Close the window — KeepClean fully quits and restores all input.
2. Reopen the app and try keyboard-only mode first.
3. If that works, try the timed mode next.

## Permissions Were Revoked

If you revoke either permission (or rebuild the app from source), KeepClean returns to the setup screen on next launch. Just follow the setup steps again.

## Still Not Working?

[Open an issue](https://github.com/adhamhaithameid/keep-clean/issues) with:
- Your macOS version
- What you tried
- Any error messages shown in the app
