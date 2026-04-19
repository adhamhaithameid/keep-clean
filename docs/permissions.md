# Permissions

KeepClean needs two macOS permissions to disable your keyboard and trackpad. Both are requested through a guided setup screen the first time you open the app.

## What You'll Be Asked For

### Accessibility

- **What it does:** lets KeepClean create an event tap to intercept keyboard events.
- **Without it:** the app cannot disable the keyboard at all.
- **How to grant:** the setup screen opens System Settings for you — toggle KeepClean ON.

### Input Monitoring

- **What it does:** lets the event tap actually block events from reaching other apps.
- **Without it:** KeepClean can intercept events but cannot suppress them — keys still type.
- **How to grant:** the setup screen opens System Settings for you — add KeepClean and toggle it ON.

> **Why both?** macOS treats "seeing" keyboard events and "blocking" them as two separate permissions. KeepClean needs both to actually stop your keystrokes during cleaning.

## If the Setup Screen Doesn't Detect Your Permission

This can happen with unsigned or ad-hoc signed builds. After 10 seconds, an **"I've Already Granted It"** button appears — click it to continue. The actual blocking will work correctly as long as the permissions are toggled on in System Settings.

## If You Previously Denied Access

1. Open **System Settings → Privacy & Security**.
2. Check both **Accessibility** and **Input Monitoring**.
3. Find KeepClean in each list and toggle it ON.
4. Reopen KeepClean — it automatically returns to the setup screen if a permission is missing.

## If You Revoke Permissions Later

KeepClean checks permissions on every launch. If either is revoked, the app returns to the setup screen to guide you through re-granting them. You'll also see a banner in the main interface if a permission is missing.

If the app still doesn't work after granting permissions, see [Troubleshooting](troubleshooting.md).
