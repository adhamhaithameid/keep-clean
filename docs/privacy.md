# Privacy and Footprint

KeepClean is designed to stay small, local, and easy to trust.

## Privacy

- No account is required.
- No analytics are included.
- No sync or cloud storage is used.
- No background networking is built into the app.
- The only web actions are the About tab links that you choose to open yourself.

## Footprint

KeepClean is a very small native macOS app.

The release checks currently verify:

- bundle size
- launch time
- memory use after launch
- idle network sockets

That means the packaged app is measured before release artifacts are treated as ready.

## Why the App Stays Small

- It only supports the built-in keyboard and built-in trackpad.
- It does not try to manage external devices in this version.
- It uses native Swift and SwiftUI.
- It does not include web runtimes, background services, or update frameworks.
